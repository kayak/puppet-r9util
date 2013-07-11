module Puppet::Parser::Functions
  newfunction(:basename, :type => :rvalue) do |args|
    unless [1,2].include? args.size
      raise Puppet::ParseError.new('basename accepts one or two arguments!')
    end
    path = args[0]
    ext = args[1] || ''
    File.basename(path,ext)
  end
end
