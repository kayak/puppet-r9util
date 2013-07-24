require 'tempfile'
require 'rubygems'
require 'json'

# The purpose of this function is to help render json data
# containing hashes in a predictable fashion. Otherwise Puppet
# can end up registering changes to JSON files when there
# really aren't any (in Ruby 1.8.7).
#
# It works by forking and overriding the each function for Hash
# to sort by key before yielding.
#
# Thus the keys of any hashes in the first argument must be strings,
# or else the sort could fail.
#
# ====================================================================
# N.B. This function will break if the pure_json module starts using a
# function other than each for enumerating over hashes.
# ====================================================================
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

      # Validate that all hash keys are strings.
      def validate(obj)
        case obj
        when Hash
          unless obj.keys.all? { |k| k.is_a? String }
            raise Puppet::ParseError.new 'keys of any '     <<
              'hashes supplied to predictable_pretty_json ' << 
              'must be strings!'
          end
          obj.values.each { |v| validate(v) }
        when Array
          obj.each { |d| validate(d) }
        end
      end
    end

    utils = utils_class.new

    data = utils.coerce(data) if coerce

    unless data.kind_of?(Hash) || data.kind_of?(Array)
      next data.to_json
    end

    utils.validate(data)

    tmpfile = Tempfile.new('predictable_pretty_json')
    tmpfile.close

    # Fork to avoid contaminating anything else when we mess with
    # Hash and JSON
    pid = Process.fork do
      [$stderr,$stdout].map {|io| io.reopen(tmpfile.path,'w')}

      json = nil

      begin

        ::Hash.class_eval do
          def each
            keys.sort.each { |k| yield [k,self[k]] }
          end
        end

        require 'json/pure'
        JSON.generator = JSON::Pure::Generator

        json = JSON.pretty_generate(data)

      rescue Exception => e
        print Marshal.dump(e)
        Process.exit(1)
      end

      print json
    end

    pid,status = Process.wait2(pid)

    output = begin; File.read(tmpfile.path); rescue; end

    tmpfile.delete if File.exists?(tmpfile.path)

    unless status.success?
      msg = "Failed to generate JSON from #{data.inspect}"
      msg << ": #{Marshal.load(output)}" unless output.nil?
      fail(msg)
    end

    output
  end
end
