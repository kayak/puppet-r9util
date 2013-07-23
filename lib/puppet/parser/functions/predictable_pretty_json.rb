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
    unless [1,2].include?(args.size)
      raise Puppet::ParseError.new('predictable_pretty_json expects 1-2 args')
    end

    data = args[0]
    coerce = (args[1].to_s == 'true')

    utils_class = Class.new do

      # Convert strings that look like booleans, null, or numbers into
      # appropriate ruby types.
      def coerce(obj)
        case obj
        when Hash
          Hash[obj.map { |k,v| [k.to_s,coerce(v)] }]
        when Array
          obj.map { |i| coerce(i) }
        when 'true'
          true
        when 'false'
          false
        when 'nil',:nil,'undef',:undef
          nil
        when /\A\d+\z/
          obj.to_i
        when /\A\d+\.\d+\z/
          obj.to_f
        else
          obj
        end
      end

      # Make iterators of any hashes in the structure sort by key
      def normalize(obj)

        if obj.kind_of?(Hash)
          unless obj.keys.all? { |k| k.kind_of? String }
            raise Puppet::ParseError.new('keys of any hashes supplied ' << 
                     'to predictable_pretty_json must be strings!')
          end

          def obj.each
            keys.sort.map { |k| yield [k,self[k]] }
          end

          obj.values.each { |v| normalize(v) }

        elsif obj.kind_of?(Array)
          obj.each { |d| normalize(d) }
        end
      end

    end

    utils = utils_class.new

    data = utils.coerce(data) if coerce

    # pretty_generate only accepts hashes and arrays as arguments.
    unless data.kind_of?(Hash) || data.kind_of?(Array)
      next data.to_json
    end

    utils.normalize(data)

    JSON.pretty_generate(data)
  end
end
