require 'spec_helper'

describe Puppet::Type.type(:gcs_download) do

  describe 'when validating arguments' do

    let(:default_args) do
      {
        :title       => 'a',
        :bucket      => 'b',
        :remote_path => 'c',
      }
    end

    it 'should have correct defaults' do
      resource = new_resource(default_args)
      resource[:always_check_md5].should == false
      resource[:ensure].should == :present
    end

    it 'should set local path to title' do
      resource = new_resource(default_args)
      resource[:local_path].should == 'a'
    end

    it 'should raise an error if bucket and remote path are not supplied' do
      should_raise_resource_error_for_args({})
      should_raise_resource_error_for_args({ :ensure => :present })
      should_raise_resource_error_for_args({ :bucket => 'b' })
      should_raise_resource_error_for_args({ :remote_path => 'c' })
    end

    it 'should not raise an error if bucket and remote are not supplied and ensure is absent' do
      expect {
        new_resource({ :ensure => :absent })
      }.not_to raise_error
    end

    it 'should raise an error with bad always_check_md5 value' do
      expect {
        new_resource(default_args.merge(:always_check_md5 => 'nonsense'))
      }.to raise_error(Puppet::ResourceError)
    end

    it 'should raise an error with bad ensure value' do
      expect {
        new_resource(default_args.merge(:ensure => 'nonsense'))
      }.to raise_error(Puppet::ResourceError)
    end

    def new_resource(args = {})
      args = { :title => 'a' }.merge(args)
      Puppet::Type.type(:gcs_download).new(args)
    end

    def should_raise_resource_error_for_args(args)
      expect {
        new_resource(args)
      }.to raise_error(Puppet::ResourceError, /bucket and remote_path.*required/)
    end

  end
end
