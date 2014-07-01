require 'spec_helper'

describe 'r9util::download' do

  context('with default parameters') do

    let(:title){ 'http://foo.com/myfile' }

    it 'should try to download the file' do
      should contain_exec('r9util-download-http://foo.com/myfile').with({
        :path => ['/bin','/usr/bin'],
        :command => 'wget -T 300 -O /root/myfile http://foo.com/myfile',
        :creates => '/root/myfile',
      })
    end

  end


  context('with timeout and path parameters') do
    let(:title){ 'download-1' }

    let(:params) do
      { 
        :url     => 'a.com/myfile',
        :path    => '/tmp/foo',
        :timeout => 30,
      }
    end

    it 'should try to download the file' do
      should contain_exec('r9util-download-download-1').with({
        :path => ['/bin', '/usr/bin'],
        :command => "wget -T 30 -O /tmp/foo a.com/myfile",
        :creates => '/tmp/foo',
      })
    end
  end

  context('with md5sum parameter') do
    let(:title){ 'title' }
    let(:params) do
      { 
        :url     => 'a.com/file',
        :path    => '/tmp/foo',
        :timeout => 30,
        :md5sum  => '0fee8043ecd6e382f8abcee023f24ecd',
      }
    end

    it 'should md5sum the file' do
      check = 'echo "0fee8043ecd6e382f8abcee023f24ecd  /tmp/foo" | md5sum --check'

      should contain_exec('r9util-download-title').with({
        :path    => ['/bin', '/usr/bin'],
        :command => 'wget -T 30 -O /tmp/foo a.com/file',
        :unless  => check,
      })

      should contain_exec('r9util-download-title-md5check').with({
        :path        => ['/bin', '/usr/bin'],
        :command     => check,
        :refreshonly => true,
      })
    end
    
  end


  context('with parameters with weird characters') do
    let(:title){ 'quoty' }

    let(:params) do
      { 
        :url     => 'a.com/myfile?b=1',
        :path    => '/tmp/!f o o',
        :timeout => 30,
        :md5sum  => 'abc',
      }
    end

    it 'should shellquote properly' do
      check = "echo 'abc  /tmp/!f o o' | md5sum --check"

      should contain_exec('r9util-download-quoty').with({
         :command => "wget -T 30 -O '/tmp/!f o o' \"a.com/myfile?b=1\"",
         :unless  => check,
      })

      should contain_exec('r9util-download-quoty-md5check').with({
         :command => check,
      })
    end
  end


end
