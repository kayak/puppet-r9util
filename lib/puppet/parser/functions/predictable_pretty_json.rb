require 'open3'

# predictable_pretty_json - render JSON data containing hashes in a predictable
# fashion, by sorting hashes by key first.
#
# On Ruby 1.8.7, puppet sometimes registers changes to JSON files when there
# aren't any changes to the data structure. This function is a fix for that 
# behavior -- JSON for the same data structure will render the same every time.
#
# The function also takes a second parameter, coerce, that when true will 
# convert strings that look like numbers, booleans, or null, into the 
# appropriate Ruby types before rendering the JSON. Defaults to false.
#
# N.B. This function is slow and depends on internals of the JSON gem
#
# Example:
#
# $data = {
#   'foo' => { 'a' => '1', 'z' => '2' }
# }
#
# predictable_pretty_json($data) =>
# '{
#   "foo": {
#     "a": "1",
#     "z": "2"
#   }
# }'
# 
# predictable_pretty_json($data,true) =>
# ' {
#    "foo": {
#      "a": 1,
#      "z": 2
#    }
# }'
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
            raise Puppet::ParseError.new 'keys of any '   <<
              'hashes passed to predictable_pretty_json ' << 
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

    render_script = <<SCRIPT
begin
  require 'rubygems'
  require 'json/pure'

  data = Marshal.load(#{Marshal.dump(data).inspect})

  class Hash
    def each
      keys.sort.each { |k| yield [k,self[k]] }
    end
  end

  print JSON.pretty_generate(data)
rescue Exception => e
  $stderr.print e.class << ' ' << e.message
end
EOF
SCRIPT

    json,error = nil,nil

    Open3.popen3('/usr/bin/env ruby') do |stdin,stdout,stderr|
      stdin.write(render_script)
      stdin.close
      json = stdout.read
      error = stderr.read
    end

    unless $?.success?
      raise Puppet::ParseError.new "Failed to generate JSON from #{data.inspect}: #{error}"
    end

    json
  end
end
