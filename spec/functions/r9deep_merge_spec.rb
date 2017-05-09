require 'spec_helper'

describe 'the r9deep_merge function' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  def expect_parse_error(argument)
    lambda { scope.function_r9deep_merge(argument) }.should(raise_error(Puppet::ParseError))
  end

  def expect_deep_merge(expected,args)
    scope.function_r9deep_merge(args).should == expected
  end

  it 'should raise a ParseError if the number of arguments is not 2 or 3' do
    expect_parse_error([])
    expect_parse_error(['a'])
    expect_parse_error(['a','b','c','d'])
  end

  it 'should return right-most object when given mismatching types' do
    expect_deep_merge('foo',[nil,'foo'])
    expect_deep_merge(nil,['foo',nil])
    expect_deep_merge('foo',[:foo,'foo'])
    expect_deep_merge('foo',[{'foo' => 2},'foo'])
    expect_deep_merge({'foo' => 2},['foo',{'foo' => 2}])
    expect_deep_merge('foo',[1,'foo'])
    expect_deep_merge(1,['foo',1])
  end

  it 'should return right-most object when objects are not hashes or arrays' do
    expect_deep_merge('foo',['bar','foo'])
    expect_deep_merge('bar',['foo','bar'])
    expect_deep_merge(:bar,[:foo,:bar])
    expect_deep_merge(10,[5,10])
    expect_deep_merge(nil,[nil,nil])
  end

  it 'should not merge arrays in default mode' do
    expect_deep_merge([2],[[1],[2]])
    expect_deep_merge([{:b => 1}],[[{:a => 1}],[{:b => 1}]])
  end

  it 'should properly index merge arrays in index mode' do
    expect_deep_merge([2],[[1],[2],'index'])
    expect_deep_merge([{:a => 1,:b => 1}],[[{:a => 1}],[{:b => 1}],'index'])
  end

  it 'should properly union merge arrays in union mode' do
    expect_deep_merge([1,2],[[1],[2],'union'])
    expect_deep_merge([{:a => 1},{:b => 1}],[[{:a => 1}],[{:b => 1}],'union'])
  end

  it 'should properly merge hashes' do
    expect_deep_merge({:a => 1,:b => 2,:c => 3},
                     [{:a => 1,:b => 3},{:b => 2,:c => 3}])
  end

  it 'should merge things recursively' do
    a = {
      'p' => {
        'q' => [{ 'x' => [1,2,3,4],
                  'y' => {
                    'a' => 1,
                  },
                  'z' => nil,
                },
                { 'j' => 'k' },
                [[1],[2],[3,4]],
                nil,
               ],
        't' => nil,
      },
      'r' => 3,
    }

    b = {
      'p' => {
        'q' => [{ 'x' => [1,2,4],
                  'y' => {
                    'a' => 100,
                  },
                  'z' => nil,
                },
                { 'j' => 'k' },
                [[1],[2],[100]],
               ],
      },
      's' => 100,
    }

    expected_none = {
      'p' => {
        'q' => [{ 'x' => [1,2,4],
                  'y' => {
                    'a' => 100,
                  },
                  'z' => nil,
                },
                { 'j' => 'k' },
                [[1],[2],[100]],
               ],
        't' => nil,
      },
      'r' => 3,
      's' => 100,
    }

    expected_index = {
      'p' => {
        'q' => [{ 'x' => [1,2,4,4],
                  'y' => {
                    'a' => 100,
                  },
                  'z' => nil,
                },
                { 'j' => 'k' },
                [[1],[2],[100,4]],
                nil,
               ],
        't' => nil,
      },
      'r' => 3,
      's' => 100,
    }

    expected_union = {
      'p' => {
        'q' => [{ 'x' => [1,2,3,4],
                  'y' => {
                    'a' => 1,
                  },
                  'z' => nil,
                },
                { 'j' => 'k' },
                [[1],[2],[3,4]],
                nil,
                { 'x' => [1,2,4],
                  'y' => {
                    'a' => 100,
                  },
                  'z' => nil,
                },
                [[1],[2],[100]],
               ],
        't' => nil,
      },
      'r' => 3,
      's' => 100,
    }

    expect_deep_merge(expected_none,[a,b,'none'])
    expect_deep_merge(expected_index,[a,b,'index'])
    expect_deep_merge(expected_union,[a,b,'union'])
  end
end
