require 'rubygems'
require 'json'

# The purpose of this function is to help render json data
# containing hashes in a predictable fashion. Otherwise Puppet
# can end up registering changes to json files when there
# really aren't any.
#
# It works by overriding the each function for any hashes in
# the supplied data structure to sort by key before yielding.
# Thus all keys must be strings.
#
# (This function will break if the pure_json module starts using
# a function other than each for enumerating over hashes)
#
module Puppet::Parser::Functions
  newfunction(:predictable_pretty_json,:type => :rvalue) do |args|
    if args.size != 1
      raise Puppet::ParseError.new('predictable_pretty_json expects a single argument')
    end

    data = args.first

    unless data.kind_of?(Hash) || data.kind_of?(Array)
      next data.to_json
    end

    normalize = lambda do |obj|
      if obj.kind_of?(Hash)
        unless obj.keys.all? { |k| k.kind_of? String }
          raise Puppet::ParseError.new('keys of any hashes supplied to predictable_pretty_json must be strings!')
        end
        def obj.each
          keys.sort.map { |k| yield [k,self[k]] }
        end
        obj.values.each { |v| normalize.call(v) }
      elsif obj.kind_of?(Array)
        obj.each { |d| normalize.call(d) }
      end
    end

    normalize.call(data)
    JSON.pretty_generate(data)
  end
end
