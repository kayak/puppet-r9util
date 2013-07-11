require 'spec_helper'

describe 'the quote_properties function' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  def expect_parse_error(argument)
    lambda { scope.function_quote_properties(argument) }.should(raise_error(Puppet::ParseError))
  end

  def expect_quote_properties(expected,input)
    scope.function_quote_properties([input]).should == expected
  end

  it 'should raise a ParseError if the number of arguments is not 1' do
    expect_parse_error([])
    expect_parse_error(['a','b'])
  end

  it 'should raise a ParseError if the property name or value contains both single or double quotes' do
    expect_parse_error([{ 'a' => '"f\'"', 'b' => '1'}])
    expect_parse_error([{ '"\'' => '2'}])
  end

  it 'should properly quote strings' do
    expect_quote_properties({
                              "'a'" => "'b'",
                              "'a b c'" => "'c d'",
                              '"don\'t"' => "'run'",
                              "'run'" => '"don\'t"',
                              "'\"foo\"'" => "'bar'",
                              "'foo'" => "'\"bar\"'",
                            },
                            {
                              'a' => 'b',
                              'a b c' => 'c d',
                              "don't" => 'run',
                              'run' => "don't",
                              '"foo"' => 'bar',
                              'foo' => '"bar"',
                            })
  end
end
