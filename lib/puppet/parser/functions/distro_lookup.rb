# distro_lookup - a simple way to configure various package / service / etc
#   names for different Linux distributions and OS versions.
#
# Example:
# $package_names = {
#   'CentOS' => {
#     5 => 'oldpackage',
#     6 => 'newpackage'
#   },
#   'Ubuntu'  => 'debpackage',
#   'default' => 'foopackage'
# }
#
# CentOS 5.7 node:
# distro_lookup($package_names) -> 'oldpackage'
#
# CentOS 6.3 node:
# distro_lookup($package_names) => 'newpackage'
#
# Ubuntu 12.04 node:
# distro_lookup($package_names) -> 'debpackage'
#
# Darwin X.Z node:
# distro_lookup($package_names) -> 'foopackage'
#
module Puppet::Parser::Functions
  newfunction(:distro_lookup, :type => :rvalue) do |args|
    if args.size != 1
      raise Puppet::ParseError.new('distro_lookup only accepts one argument!')
    end
    data = args.first

    # In Puppet, a hash declared as { 1 => 'a' } will be passed to
    # this function as { '1' => 'a' }. In Ruby, { 1 => 'a' } will be
    # passed as declared. We want this function to yield consistent
    # results when invoked from either language, so we convert all
    # hash keys to strings before looking up values.
    debug "distro_lookup: Converting all keys in data to strings..."

    fix = Proc.new do |data|
      next data unless data.kind_of? Hash

      Hash[*data.map { |k,v| [k.to_s, fix.call(v)] }.flatten]
    end

    data = fix.call(data)

    os = lookupvar('::operatingsystem')
    osver = lookupvar('::operatingsystemrelease')

    osmaj,osmin = osver.to_s.split('.')

    default = nil

    [os,osmaj,osmin].inject(data) do |node,factval|
      next node unless node.kind_of?(Hash)

      default = node['default'] unless node['default'].nil?

      next node[factval] if ! factval.nil? && node.has_key?(factval)
      next default unless default.nil?

      raise Puppet::ParseError.new 'could not determine a ' <<
        "value for OS #{os} version #{osver} in #{data.inspect}"
    end
  end
end
