class Rack::Router
  
  SEGMENT_REGEXP         = /(:([a-z](_?[a-z0-9])*))/
  OPTIONAL_SEGMENT_REGEX = /^.*?([\(\)])/i
  SEGMENT_CHARACTERS     = "[^\/.,;?]".freeze
  
  class Condition
    
    def initialize(pattern)
      @pattern = pattern
    end
    
    def =~(other)
      @pattern == other
    end
    
  end
  
  class ConditionWithCaptures < Condition
    def initialize(pattern)
      raise ArgumentError, "pattern must be a string" unless pattern.is_a?(String)
      
      @segments = parse_segments_with_optionals(pattern.dup)
      @captures = @segments.flatten.select { |s| s.is_a?(Symbol) }
    end
    
  private
    
    def parse_segments_with_optionals(pattern, nest_level = 0)
      segments = []

      # Extract all the segments at this parenthesis level
      while segment = pattern.slice!(OPTIONAL_SEGMENT_REGEX)
        # Append the segments that we came across so far
        # at this level
        segments.concat parse_segments(segment[0..-2]) if segment.length > 1
        # If the parenthesis that we came across is an opening
        # then we need to jump to the higher level
        if segment[-1, 1] == '('
          segments << parse_segments_with_optionals(pattern, nest_level + 1)
        else
          # Throw an error if we can't actually go back down (aka syntax error)
          raise ArgumentError, "There are too many closing parentheses" if nest_level == 0
          return segments
        end
      end

      # Save any last bit of the string that didn't match the original regex
      segments.concat parse_segments(path) unless pattern.empty?

      # Throw an error if the string should not actually be done (aka syntax error)
      raise ArgumentError, "You have too many opening parentheses" unless nest_level == 0

      segments
    end
    
    def parse_segments(path)
      segments = []

      while match = (path.match(SEGMENT_REGEXP))
        segments << match.pre_match unless match.pre_match.empty?
        segments << match[2].intern
        path = match.post_match
      end

      segments << path unless path.empty?
      segments
    end
    
  end
end