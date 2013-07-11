require 'spec_helper'

describe 'the basename function' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  def expect_parse_error(argument)
    lambda { scope.function_basename(argument) }.should(raise_error(Puppet::ParseError))
  end

  def expect_basename(expected,args)
    scope.function_basename(args).should == expected
  end

  it 'should raise a ParseError if the number of arguments is not 1 or 2' do
    expect_parse_error([])
    expect_parse_error(['a','b','c'])
  end

  it 'should return the basename of a file' do
    expect_basename('foo',['/foo'])
    expect_basename('foo',['/tmp/etc/foo'])
    expect_basename('foo.tgz',['/tmp/etc/foo.tgz'])
    expect_basename('foo.tgz',['/tmp/etc/foo.tgz/'])
    expect_basename('foo',['/tmp/etc/foo.tgz/','.tgz'])
  end

  it 'should return the basename of a url' do
    expect_basename('foo',['http://blah.com/foo'])
    expect_basename('foo',['http://blah.com/foo.tar','.tar'])
  end
end
