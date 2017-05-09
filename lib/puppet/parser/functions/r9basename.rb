module Puppet::Parser::Functions
  newfunction(:r9basename, :type => :rvalue) do |args|
    unless [1,2].include? args.size
      raise Puppet::ParseError.new('r9basename accepts one or two arguments!')
    end
    path = args[0]
    ext = args[1] || ''
    File.basename(path,ext)
  end
end
