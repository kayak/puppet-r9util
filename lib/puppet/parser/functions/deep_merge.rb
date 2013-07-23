#
# Deep-merge a JSON-style data structure consisting of nested hashes,
# arrays, and primitives. 
#
# Supports three kinds of array merges:
#   - none: do not try to merge arrays, treat them like primitives
#   - union: union the elements of the two arrays
#   - index: merge the arrays as if they were hashes with indexes for
#     keys (child elements will be deep-merged)
#
module Puppet::Parser::Functions
  newfunction(:deep_merge, :type => :rvalue) do |args|
    unless [2,3].include?(args.size)
      raise Puppet::ParseError.new('deep_merge expects 2-3 arguments')
    end

    merger_class = Class.new do
      def initialize(array_merge = :none)
        @array_merge = (array_merge || :none).to_sym
      end

      def hashify(array)
        indexed = []
        array.each_with_index { |e,i| indexed << [i,e] }
        Hash[indexed]
      end

      def unhashify(hash)
        hash.sort { |a,b| a.first <=> b.first }.map { |k,v| v }
      end

      def deep_merge(a,b)
        if a.class == b.class && [Array,Hash].include?(a.class)
          a.is_a?(Hash) ?
            deep_merge_hashes(a,b) :
            deep_merge_arrays(a,b)
        else
          b
        end
      end

      def deep_merge_arrays(a,b)
        case @array_merge
        when :index
          # Deep-merge the arrays as though they are hashes with
          # indexes as keys
          unhashify(deep_merge_hashes(hashify(a),hashify(b)))

        when :union
          # Union the two arrays
          a | b

        else
          # Prefer the right-most argument
          b
        end
      end
      
      def deep_merge_hashes(a,b)
        a.merge(b) { |key,av,bv| deep_merge(av,bv) }
      end

    end

    a,b = args[0..1]
    merger = merger_class.new(args[2])
    merger.deep_merge(a,b)
  end
end
