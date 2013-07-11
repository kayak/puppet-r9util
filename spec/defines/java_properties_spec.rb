require 'spec_helper'

describe 'r9util::java_properties' do

  context('properties not a hash') do
    let(:title){ 'imaginaryfile' }
    let(:params){ { :properties => 1 } }

    it 'should raise an error' do
      expect {
        should contain_augeas('update-imaginaryfile-properties')
      }.to raise_error(Puppet::Error)
    end
  end

  context('with empty properties') do
    let(:title) { 'foo' }

    it 'should have empty changes' do
      should contain_augeas('update-foo-properties').with({
        :lens    => 'CD_Properties.lns',
        :incl    => 'foo',
        :changes => []
      })
    end
  end

  context('with multiple properties') do
    let(:title){ 'imaginaryfile' }
    let(:params) do
      { :properties => {
          'a.b.c' => false,
          'foo' => 'bar',
          '24' => 24,
          'quoted' => '"a thing"',
        }
      }
    end   
      
    it 'should construct correct augeas commands' do
      should contain_augeas('update-imaginaryfile-properties').with({
        :lens    => 'CD_Properties.lns',
        :incl    => 'imaginaryfile',
        :changes => ["set 'a.b.c' 'false'",
                     "set 'foo' 'bar'",
                     "set '24' '24'",
                     "set 'quoted' '\"a thing\"'"].sort,
      })
    end
  end
end
