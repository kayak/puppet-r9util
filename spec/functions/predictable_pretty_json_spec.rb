require 'spec_helper'

describe 'the predictable_pretty_json function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  def expect_parse_error(arglist)
    lambda { scope.function_predictable_pretty_json(arglist) }.should(raise_error(Puppet::ParseError))
  end

  def expect(string,data)
    scope.function_predictable_pretty_json([data]).should == string
  end

  it 'should raise a ParseError if the number of args is not 1 or 2' do
    expect_parse_error([])
    expect_parse_error(['','',''])
  end

  it 'should raise a ParseError if any hashes in supplied data structure do not have strings as keys' do
    expect_parse_error([{ :a => 'a'}])
    expect_parse_error([[{:a => 'a'}]])
    expect_parse_error([{ 'a' => { :a => 'a'}}])
  end

  it 'should yield same ouput as to_json for data types' do
    [32,
     false,
     true,
     nil].each do |object|
      expect(object.to_json,object)
    end    
  end

  it 'should yield same output as pretty_generate for simple arrays and hashes objects' do
    [[],
     {},
     {'a' => '1'},
     [1,{ 'a' => '1' }],
     { 'a' => true }].each do |object|
      expect(JSON.pretty_generate(object),object)
    end
  end

  it 'should yield predictable JSON for hashes' do
    expected = <<JSON
{
  "a": 1,
  "b": 1
}
JSON
    expect(expected.chomp,{'a' => 1,'b' => 1})

    expected = <<JSON
[
  {
    "a": 1,
    "b": 1
  }
]
JSON
    expect(expected.chomp,[{'a' => 1,'b' => 1}])

    data = [
            {
              'z' => {
                'aX' => 1,
                'a0' => 1,
                'ab' => 1,
                'aZ' => 1,
                'a9' => 1,
                'ad' => 1,
              },
              'a' => {
                'd' => 1,
                'c' => 1
              },
              'b' => {
                'e' => 1,
                'g' => 1,
                'f' => 1
              },
            },
            {
              'q' => 1,
              'p' => 1
            }
           ]
    expected = <<JSON
[
  {
    "a": {
      "c": 1,
      "d": 1
    },
    "b": {
      "e": 1,
      "f": 1,
      "g": 1
    },
    "z": {
      "a0": 1,
      "a9": 1,
      "aX": 1,
      "aZ": 1,
      "ab": 1,
      "ad": 1
    }
  },
  {
    "p": 1,
    "q": 1
  }
]
JSON
    expect(expected.chomp,data)
  end

  it 'should return a useful error message if JSON cannot be generated' do
    Marshal.stubs(:dump).with(['foo']).returns(mock(:inspect => 'NONSENSE'))
    lambda { scope.function_predictable_pretty_json([['foo']]) }.should(raise_error(Puppet::Error,/\["foo"\]: uninitialized constant NONSENSE/))
  end
end
