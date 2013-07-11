# It seems that Puppet does not properly handle quote mark escaping in
# Augeas commands. If you pass Puppet an Augeas command like
#   set foo 'don\'t cry'
# you will end up with a Java property like
#   foo=don\'t cry
# when you really want
#   foo=don't cry
#
# So this is my attempt to work around that limitation, without
# requiring users to quote any/all properties with whitespace in them.
module Puppet::Parser::Functions
  newfunction(:quote_properties, :type => :rvalue) do |args|
    if args.size != 1 || ! args.first.kind_of?(Hash)
      raise Puppet::ParseError.new('distro_lookup expects a hash as an argument!')
    end

    quote = Proc.new do |string|
      has_single = string =~ /'/
      has_double = string =~ /"/
      if has_single
        if has_double
          raise Puppet::ParseError.new <<-ERROR
          Sorry, including both single and double quotes in a property
          name or value is not supported by the java_properties type.
          Try disabling quoting by setting the java_properties
          auto_quote parameter to false.
          ERROR
        else
          "\"#{string}\""
        end
      else
        "'#{string}'"
      end
    end

    properties = {}
    args.first.each_pair do |name,value|
      properties[quote.call(name)] = quote.call(value)
    end
    properties
  end
end
