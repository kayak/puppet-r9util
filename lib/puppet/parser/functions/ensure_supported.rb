# ensure_supported - easy way to specify the set of OSes (and versions) that
#   are supported by your module. Can either fail or warn if the node
#   is not supported.
#
# Example:
# $supported = {
#   'CentOS' => [5,6],
#   'Ubuntu' => [12],
#   'Darwin' => 'all',
# }
#
# CentOS 6 node:
# ensure_supported($supported) => true
#
# CentOS 4.3 node:
# ensure_supported($supported) => Error: "operating system CentOS
#             version 4.3 is not supported by this manifest"
# 
# CentOS 4.3 node with warn parameter set to true
# ensure_supported($supported,true) => false
#
module Puppet::Parser::Functions
  newfunction(:ensure_supported, :type => :statement) do |args|
    unless [1,2].include? args.size
      raise Puppet::ParseError.new 'The ensure_supported function ' <<
        'expects one or two arguments'
    end
    oslist,warn = args

    os = lookupvar('::operatingsystem')
    osver = lookupvar('::operatingsystemrelease')

    osmaj,osmin = osver.to_s.split('.')

    is_supported =
      case oslist
      when String
        os == oslist
      when Array
        oslist.include? os
      when Hash
        case oslist[os]
        when 'all'
          true
        when Array
          oslist[os].map { |n| n.to_s }.include? osmaj
        else
          false
        end
      else
        raise Puppet::ParseError.new("os list must " << 
                                     "be a string, array or hash!")
      end

    unless is_supported
      message = "Version #{osver.inspect} of operating system " << 
        "#{os.inspect} is not supported by this manifest"
      if warn
        warn message
      else
        raise Puppet::ParseError.new(message)
      end
    end

  end
end
