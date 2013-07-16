require 'spec_helper'

describe 'the check_supported function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:test_data) { 
    YAML.load <<TESTDATA
CentOS:
  - 5
  - 6
Ubuntu:
  - 12
Darwin: all
TESTDATA
  }

  def expect_result(value,data)
    scope.function_check_supported([data]).should == value
  end

  def mock_facts(os,version)
    scope.expects(:lookupvar).with('::operatingsystem').returns(os)
    scope.expects(:lookupvar).with('::operatingsystemrelease').returns(version)
  end

  def expect_parse_error(arglist,regex)
    lambda { scope.function_check_supported(arglist) }.should(raise_error(Puppet::ParseError,regex))
  end

  it 'should raise an error if given the wrong number of arguments' do
    re = /check_supported.*expects one or two arg/
    expect_parse_error([],re)
    expect_parse_error(['a','b','c'],re)
  end

  it 'should return true if the OS is supported' do
    [['CentOS','6.3',
      'Ubuntu','12.04',
      'CentOS','5.4',
      'Darwin','10.1']].each do |os,version|
      mock_facts(os,version)
      expect_result(true,test_data)
    end
  end

  it 'should warn and return false if OS not supported and warn is true' do
    mock_facts('FakeOS','0')
    scope.expects(:warn).with { |m| m =~ /not supported/ }
    scope.function_check_supported([test_data,true]).should == false
  end

  it 'should raise an error if the OS is not supported' do
    mock_facts('FakeOS','0')
    expect_parse_error([test_data,false],/not supported/)
  end
end
