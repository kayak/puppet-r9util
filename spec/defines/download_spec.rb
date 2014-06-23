require 'spec_helper'

describe 'r9util::download' do

  context('without curl') do
    let(:title){ 'http://foo.com/myfile' }

    it 'should raise an error' do
      expect {
        should contain_exec('r9util-download-http://foo.com/myfile')
      }.to raise_error(Puppet::Error,/curl is required/)
    end
  end

  context('with default parameters') do

    let(:title){ 'http://foo.com/myfile' }
    let(:facts){ { 'r9util_download_curl_version' => '7.0.0' } }

    it 'should try to download the file' do
      should contain_exec('r9util-download-http://foo.com/myfile').with({
        :path => ['/bin','/usr/bin'],
        :command => 'curl -L --create-dirs -m 300 "http://foo.com/myfile" -o "/root/myfile"',
        :creates => '/root/myfile'
      })
    end

  end

  context('with custom parameters') do
    let(:title){ 'my-silly-title' }
    let(:facts){ { 'r9util_download_curl_version' => '7.0.0' } }
    let(:params) do
      { 
        :url     => 'a.com/myfile',
        :path    => '/tmp/foo',
        :timeout => 30,
      }
    end

    it 'should try to download the file' do
      should contain_exec('r9util-download-my-silly-title').with({
        :path => ['/bin','/usr/bin'],
        :command => 'curl -L --create-dirs -m 30 "a.com/myfile" -o "/tmp/foo"',
        :creates => '/tmp/foo'
      })
    end
  end

  context('with md5sum parameter') do
    @md5sum = '0fee8043ecd6e382f8abcee023f24ecd'

    let(:title){ 'title' }
    let(:facts){ { 'r9util_download_curl_version' => '7.0.0' } }
    let(:params) do
      { 
        :url     => 'a.com/file',
        :path    => '/tmp/foo',
        :timeout => 30,
        :md5sum  => '0fee8043ecd6e382f8abcee023f24ecd',
      }
    end

    it 'should try to download the file' do
      check = "echo '0fee8043ecd6e382f8abcee023f24ecd  /tmp/foo' | md5sum --check"

      should contain_exec('r9util-download-title').with({
        :path => ['/bin', '/usr/bin'],
        :command => 'curl -L --create-dirs -m 30 "a.com/file" -o "/tmp/foo"',
        :unless  => check,
      })

      should contain_exec('r9util-download-title-md5check').with({
        :path        => ['/bin', '/usr/bin'],
        :command     => check,
        :refreshonly => true,
      })
    end
    
  end
end
