require 'spec_helper'
require 'webmock/rspec'
require 'tempfile'

describe Puppet::Type.type(:gcs_download).provider(:ruby) do

  let(:local_file) { @tempfile }
  let(:bucket) { 'mybucket' }
  let(:remote_file_relative) { 'foo.tgz' }
  let(:remote_file) { '/mybucket/foo.tgz' }

  before do
    tmp = Tempfile.new('puppet-r9util-gcs_download-spec')
    @tempfile = tmp.path
    tmp.close
    tmp.unlink
  end

  describe 'exist?' do

    context 'when always_check_md5 is false' do

      it 'should be false if file does not exist' do
        get_provider.exists?.should == false
      end

      it 'should be true if file exists' do
        write_local_file('blah blah')
        get_provider.exists?.should == true
      end

    end

    context 'when always_check_md5 is true' do

      let(:provider) { get_provider(:always_check_md5 => true) }

      it 'should be nil if file does not exist' do
        provider.exists?.should == nil
      end

      it 'should return false if file exists and md5 does not match API' do
        write_local_file('Some bad data')

        stub_gcs_request(:head, remote_file).
          to_return(gcs_head_response(200, 'Good data'))

        provider.exists?.should == false
      end

      it 'should return true if file exists and md5 matches API' do
        write_local_file('Good data')

        stub_gcs_request(:head, remote_file).
          to_return(gcs_head_response(200, 'Good data'))

        provider.exists?.should == true
      end

      it 'should raise an error if the file exists and API call returns 404' do
        write_local_file('')
        stub_gcs_request(:head, remote_file).to_return(gcs_head_response(404))

        expect { provider.exists? }.to raise_error(GCSDownloader::Error, /404/)
      end

      it 'should raise an error if the file exists and API call returns 301' do
        write_local_file('')
        stub_gcs_request(:head, remote_file).to_return(gcs_head_response(301))

        expect { provider.exists? }.to raise_error(GCSDownloader::Error, /301/)
      end

      it 'should raise an error if the md5 header is missing' do
        write_local_file('')
        stub_gcs_request(:head, remote_file).to_return(gcs_head_response(200))

        expect { 
          provider.exists?
        }.to raise_error(GCSDownloader::Error, /header x-goog-hash was missing/)
      end

      it 'should raise an error if the md5 header has an unxpected value' do
        write_local_file('')

        response = gcs_head_response(200)
        response[:headers] = { 'x-goog-hash' => ['utter nonsense'] }

        stub_gcs_request(:head, remote_file).to_return(response)

        expect {
          provider.exists?
        }.to raise_error(GCSDownloader::Error, /unexpected value: "utter nonsense"/)
      end
    end
  end

  describe 'create' do
    let(:provider) { get_provider }

    it 'should download the file if it does not exist' do
      stub_gcs_request(:get, remote_file).
        to_return(gcs_get_response(200, 'Good data'))

      provider.create.should == true

      File.read(local_file).should == 'Good data'
    end

    it 'should download the file if there is an md5 mismatch' do
      write_local_file('Bad data')

      stub_gcs_request(:head, remote_file).
        to_return(gcs_head_response(200, 'Good data'))

      stub_gcs_request(:get, remote_file).
        to_return(gcs_get_response(200, 'Good data'))

      provider.create.should == true

      File.read(local_file).should == 'Good data'
    end

    it 'should not download the file if it exists and matches' do
      write_local_file('Good data')

      stub_gcs_request(:head, remote_file).
        to_return(gcs_head_response(200, 'Good data'))

      provider.create.should == false

      File.read(local_file).should == 'Good data'
    end

    it 'should raise an error if the downloaded file does not match checksum' do
      response = gcs_head_response(200, 'Good data')
      response[:body] = 'Bad data!'

      stub_gcs_request(:get, remote_file).to_return(response)

      expect {
        provider.create
      }.to raise_error(GCSDownloader::Error, /md5 check after download failed/)
    end
  end

  describe 'destroy' do
    let(:provider) { get_provider }

    it 'should delete the file' do
      write_local_file('blah blah')
      File.exists?(local_file).should == true

      provider.destroy
      File.exists?(local_file).should == false
    end
  end

  after do
    File.delete(@tempfile) if File.exists?(@tempfile)
  end

  def get_provider(args = {})
    args = {
      :title       => local_file,
      :bucket      => bucket,
      :remote_path => remote_file_relative,
    }.merge(args)

    Puppet::Type.type(:gcs_download).new(args).provider
  end

  def write_local_file(content = '', &block)
    File.open(@tempfile, 'w') do |f| 
      f.write(content)
      yield f if block_given?
    end
  end

  def gcs_get_response(status, body)
    opts = gcs_head_response(status, body)
    opts[:body] = body
    opts
  end

  def gcs_head_response(status, body = nil)
    opts = { :status => status }

    unless body.nil?
      headers = { 'x-goog-hash' => generate_fake_x_goog_hash(body) }
      opts[:headers] = headers
    end

    opts
  end

  def generate_fake_x_goog_hash(md5_data)
    encoded = Base64.encode64(Digest::MD5.digest(md5_data))
    ['crc32c=blahdontcare==', "md5=#{encoded}" ]
  end

  def stub_gcs_request(method, path)
    stub_request(method, "http://storage.googleapis.com#{path}")
  end
end
