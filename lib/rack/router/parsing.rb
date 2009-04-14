class Rack::Router
  SEGMENT_REGEXP          = /(?:(:|\*)([a-z](?:_?[a-z0-9])*))/i
  OPTIONAL_SEGMENT_REGEXP = /^(?:|.*?[^\\])(?:\\\\)*([\(\)])/ 
  ESCAPED_REGEXP          = /(?:^|[^\\])\\(?:\\\\)*$/
  
  module Parsing
    
    def parse(pattern, &block)
      parse_optional_segments(pattern, 0) { |subpattern| parse_segments(subpattern, &block) }
    end
    
    module_function :parse
    
  private
  
    def parse_optional_segments(pattern, nest_level, &block)
      segments = []
      
      raise ArgumentError, "a block must be supplied" unless block_given?

      # Extract all the segments at this parenthesis level
      while segment = pattern.slice!(OPTIONAL_SEGMENT_REGEXP)
        # Append the segments that we came across so far
        # at this level
        segments.concat yield(segment[0..-2]) if segment.length > 1
        # If the parenthesis that we came across is an opening
        # then we need to jump to the higher level
        if segment[-1, 1] == '('
          segments << parse_optional_segments(pattern, nest_level + 1, &block)
        else
          # Throw an error if we can't actually go back down (aka syntax error)
          raise ArgumentError, "There are too many closing parentheses" if nest_level == 0
          return segments
        end
      end

      # Save any last bit of the string that didn't match the original regex
      segments.concat yield(pattern) unless pattern.empty?

      # Throw an error if the string should not actually be done (aka syntax error)
      raise ArgumentError, "You have too many opening parentheses" unless nest_level == 0

      segments
    end
    
    module_function :parse_optional_segments

    def parse_segments(path, &block)
      segments = []

      while match = (path.match(SEGMENT_REGEXP))
        segment_name = match[2].to_sym
        
        # Handle false-positives due to escaped special characters
        if match.pre_match =~ ESCAPED_REGEXP
          segments << "#{match.pre_match[0..-2]}#{match[0]}"
        else
          segments << match.pre_match unless match.pre_match.empty?
          segments << segment_name
          
          yield(segment_name, match[1])
        end
        
        path = match.post_match
      end

      segments << path unless path.empty?
      segments
    end
    
    module_function :parse_segments
    
  end
end