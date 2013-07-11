require 'spec_helper'

describe 'the distro_lookup function' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:test_data) { 
    YAML.load <<TESTDATA
CentOS:
  4: pack1
  5: pack2
  default: pack3
Ubuntu:
  12: pack4
Debian:
  7:
    1: pack5
    default: pack6
Darwin: pack7
default: pack8
TESTDATA
  }

  def mock_facts(os,version)
    scope.expects(:lookupvar).with('::operatingsystem').returns(os)
    scope.expects(:lookupvar).with('::operatingsystemrelease').returns(version)
  end

  def expect_package(name,data)
    scope.function_distro_lookup([data]).should == name
  end

  def expect_parse_error(argument)
    lambda { scope.function_distro_lookup(argument) }.should(raise_error(Puppet::ParseError))
  end

  it 'should raise a ParseError if there is less than 1 argument' do
    expect_parse_error([])
  end

  it 'should raise a ParseError if no match' do
    mock_facts('CentOS','5.8')
    no_defaults = {'foo' => 'bar'}
    expect_parse_error([no_defaults])
  end

  it 'should return correct OS and version value' do
    mock_facts('CentOS','5.8')
    expect_package('pack2',test_data)

    mock_facts('Ubuntu','12.04')
    expect_package('pack4',test_data)

    mock_facts('Debian','7.1')
    expect_package('pack5',test_data)
  end

  it 'should return default OS version value if present' do
    mock_facts('CentOS','6.3')
    expect_package('pack3',test_data)

    mock_facts('Darwin','10.5.4')
    expect_package('pack7',test_data)

    mock_facts('Debian','7.0')
    expect_package('pack6',test_data)
  end

  it 'should return default value if present' do
    mock_facts('RandomOS','0.21')
    expect_package('pack8',test_data)

    mock_facts('Ubuntu','14.04')
    expect_package('pack8',test_data)

    mock_facts('Debian','8.01')
    expect_package('pack8',test_data)

    mock_facts('Debian',nil)
    expect_package('pack8',test_data)

    mock_facts(nil,nil)
    expect_package('pack8',test_data)
  end

  it 'should return data argument if data is not a hash' do
    mock_facts('CentOS','6.3')
    expect_package('something','something')

    mock_facts('CentOS','6.3')
    expect_package([],[])

    mock_facts('CentOS','6.3')
    expect_package(nil,nil)
  end
end
