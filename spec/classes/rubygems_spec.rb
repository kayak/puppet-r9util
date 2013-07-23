require 'spec_helper'

describe 'r9util::rubygems' do
  it 'should declare the rubygems package' do
    should contain_package('rubygems').with_ensure('installed')
  end
end
