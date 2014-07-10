require 'base64'
require 'digest/md5'
require 'net/http'
require 'tempfile'
require 'fileutils'
require 'benchmark'

Puppet::Type.type(:gcs_download).provide(:ruby) do
  desc 'Downloads files from Google Cloud Storage'

  def exists?
    if @resource.always_check_md5?
      get_downloader.md5_match?
    else
      File.exists?(@resource[:local_path])
    end
  end

  def create
    download_if_md5_mismatch
  end

  def destroy
    File.unlink(@resource[:local_path])
  end

  def download_if_md5_mismatch
    get_downloader.download_if_md5_mismatch
  end

  private

  def get_downloader
    GCSDownloader.new(@resource[:bucket],
                      @resource[:remote_path],
                      @resource[:local_path])
  end

  class GCSDownloader

    Error = Class.new(RuntimeError)

    HOST = 'storage.googleapis.com'
    MD5_HEADER = 'x-goog-hash'

    attr_accessor :bucket, :remote_path, :local_path

    def initialize(bucket, remote_path, local_path)
      @bucket      = bucket
      @remote_path = remote_path
      @local_path  = local_path
    end

    def md5_match?
      local_md5 = file_md5(local_path)

      return nil if local_md5.nil?

      local_md5 == fetch_remote_md5
    end

    def download_if_md5_mismatch
      return false if md5_match?

      create_tmpfile do |tmpfile|
        remote_md5 = download(tmpfile)
        local_md5  = file_md5(tmpfile)

        unless local_md5 == remote_md5
          fail Error.new "md5 check after download failed " << 
            "(expected #{remote_md5}, got #{local_md5}"
        end

        FileUtils.mkdir_p(File.dirname(local_path))
        FileUtils.mv(tmpfile, local_path)

        true
      end
    end

    private

    def create_tmpfile(&block)
      begin
        file = Tempfile.new('puppet-r9util-gcs-download')
        yield file.path
      ensure
        file.close unless file.closed?
        file.unlink
      end
    end

    def request_uri
      uri = File.join("http://#{HOST}", bucket, remote_path)
      URI(uri)
    end

    def file_md5(path)
      return nil unless File.exists?(path)

      Digest::MD5.file(path)
    end

    # Downloads file, returning md5sum supplied in x-goog-hash header
    # http://ruby-doc.org/stdlib-2.1.2/libdoc/net/http/rdoc/Net/HTTP.html#class-Net::HTTP-label-Streaming+Response+Bodies
    def download(download_path)
      start_gcs_http do |http|
        request = Net::HTTP::Get.new(request_uri.path)
        http.request(request) do |response|
          check_response(response)

          Puppet.notice("Downloading file #{request_uri}")

          time = Benchmark.realtime do
            File.open(download_path, 'w') do |file|
              response.read_body { |chunk| file.write(chunk) }
            end
          end

          Puppet.notice("Download finished in #{'%.02f' % time} seconds")

          return extract_md5(response[MD5_HEADER])
        end
      end
    end

    def fetch_remote_md5
      response = start_gcs_http do |http|
        http.head(request_uri.path)
      end
      check_response(response)
      extract_md5(response[MD5_HEADER])
    end

    def start_gcs_http(&block)
      uri = request_uri
      Net::HTTP.start(uri.host, uri.port, &block)
    end

    def check_response(response)
      if response.is_a?(Net::HTTPOK)
        if response[MD5_HEADER].nil?
          fail Error.new "Got 200 response for #{request_uri}, but " <<
            "header #{MD5_HEADER} was missing?"
        end

      elsif response.is_a?(Net::HTTPNotFound)
        fail Error.new "Got 404 response for #{request_uri}, " << 
          'please check bucket and remote_path parameters'

      else
        fail Error.new 'Got unexpected reponse for ' << 
          "#{request_uri}: #{response.code} #{response.message}"
      end
    end

    def extract_md5(md5_header)
      if md5_header =~ /md5=(.*)([\s,]|\z)/
        encoded = $1
        decoded = Base64.decode64(encoded)
        md5 = decoded.bytes.map { |b| "%02x" % b }.join
        return md5
      else
        fail Error.new "#{MD5_HEADER} header had unexpected value: #{md5_header.inspect}"
      end
    end

  end
end
