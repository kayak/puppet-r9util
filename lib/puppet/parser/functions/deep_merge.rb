# Helper class.
class R9UtilDeepMerger
  def initialize(array_merge = :index)
    @array_merge = (array_merge || :none).to_sym
  end

  # Convert an array into a hash with indexes as keys.
  def hashify(array)
    prepped = []
    array.each_with_index { |e,i| prepped << [i,e] }
    Hash[prepped]
  end

  # Convert hashified array back into an array (preserving elt. ordering)
  def unhashify(hash)
    hash.sort { |a,b| a.first <=> b.first }.map { |k,v| v }
  end

  # Deep merge two items
  def deep_merge(a,b)
    if a.class == b.class && [Array,Hash].include?(a.class)
      a.is_a?(Hash) ? deep_merge_hashes(a,b) : deep_merge_arrays(a,b)
    else
      b
    end
  end

  # Merge arrays according to array merge style parameter
  def deep_merge_arrays(a,b)
    case @array_merge
    when :index
      unhashify(deep_merge_hashes(hashify(a),hashify(b)))
    when :union
      a | b
    else
      b
    end
  end

  # Merge hashes
  def deep_merge_hashes(a,b)
    a.merge(b) { |key,av,bv| deep_merge(av,bv) }
  end
end

module Puppet::Parser::Functions
  newfunction(:deep_merge, :type => :rvalue) do |args|
    unless [2,3].include?(args.size)
      raise Puppet::ParseError.new('deep_merge expects 2-3 arguments')
    end

    a,b = args[0..1]
    merger = R9UtilDeepMerger.new(args[2])
    merger.deep_merge(a,b)
  end
end
