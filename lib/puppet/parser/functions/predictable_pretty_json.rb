require 'tempfile'
require 'fileutils'

require 'rubygems'
require 'json'

# The purpose of this function is to help render JSON data
# containing hashes in a predictable fashion. Otherwise Puppet
# can end up registering changes to JSON files when there
# really aren't any (in Ruby 1.8.7).
#
# This function is a hack, it's slow, and it will break if the JSON
# gem starts using a function other than each for enumerating over
# hashes. Use at your own risk.
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

    scriptfile = Tempfile.new('predictable_pretty_json')
    scriptfile.write <<SCRIPT
#!/usr/bin/env ruby

json = nil

begin
  require 'rubygems'
  require 'json/pure'

  data = Marshal.load(#{Marshal.dump(data).inspect})

  class Hash
    def each
      keys.sort.each { |k| yield [k,self[k]] }
    end
  end

  json = JSON.pretty_generate(data)

rescue Exception => e
  print Marshal.dump(e)
  Process.exit(1)
end

print json
SCRIPT
    scriptfile.close

    FileUtils.chmod(0755,scriptfile.path)
    output = IO.popen("#{scriptfile.path} 2>&1") { |io| io.read }
    status = $?

    scriptfile.delete

    unless status.success?
      msg = "Failed to generate JSON from #{data.inspect}"

      begin
        msg << ": #{Marshal.load(output)}"
      rescue StandardError
      end

      fail(msg)
    end

    output
  end
end
