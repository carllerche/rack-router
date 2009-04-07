class Rack::Router
  SEGMENT_REGEXP          = /(?:(:|\*)([a-z](?:_?[a-z0-9])*))/i
  OPTIONAL_SEGMENT_REGEXP = /^(?:|.*?[^\\])(?:\\\\)*([\(\)])/ 
  ESCAPED_REGEXP          = /(?:^|[^\\])\\(?:\\\\)*$/
  SEGMENT_CHARACTERS      = "[^\/.,;?]".freeze
  
  class Condition
    def self.register(type)
      @@types ||= Hash.new(FallbackCondition)
      @@types[type] = self
    end    
    
    def self.build(name, pattern, segment_conditions, anchored)
      @@types[name].new(name, pattern, segment_conditions, anchored)
    end
    
    attr_reader :segments, :captures

    def initialize(method_name, pattern, conditions, anchored)
      @method_name = method_name
      @segments    = {}
      @captures    = {}
      @conditions  = conditions.dup
      @anchored    = anchored

      @conditions.default = /#{SEGMENT_CHARACTERS}+/

      case pattern
      when String
        @segments = parse_segments_with_optionals(pattern.dup)
        @pattern  = Regexp.new(anchor(compile(@segments)))
        @captures = captures_for(@segments)
      else
        @pattern = convert_to_regexp(pattern)
      end
    end

    def match(request)
      if data = @pattern.match(request.send(@method_name))
        captures = extract_captures(data)
        yield data if block_given?
        captures
      end
    end

    def generate(params, defaults = {})
      raise "Condition cannot be generated" unless @segments
      generate_from_segments(@segments, params, defaults) or raise ArgumentError, "Condition cannot be generated with #{params.inspect}"
    end

    def inspect
      @pattern.inspect
    end

  private

    # TODO: Handle escaped characters (parenthesis, colon, etc..)
    def parse_segments_with_optionals(pattern, nest_level = 0)
      segments = []

      # Extract all the segments at this parenthesis level
      while segment = pattern.slice!(OPTIONAL_SEGMENT_REGEXP)
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
      segments.concat parse_segments(pattern) unless pattern.empty?

      # Throw an error if the string should not actually be done (aka syntax error)
      raise ArgumentError, "You have too many opening parentheses" unless nest_level == 0

      segments
    end

    def parse_segments(path)
      segments = []

      while match = (path.match(SEGMENT_REGEXP))
        segment_name = match[2].to_sym
        
        # Handle false-positives due to escaped special characters
        if match.pre_match =~ ESCAPED_REGEXP
          segments << "#{match.pre_match[0..-2]}#{match[0]}"
        else
          segments << match.pre_match unless match.pre_match.empty?
          segments << segment_name
        
          @conditions[segment_name] = /.+/ if match[1] == '*'
        end
        
        path = match.post_match
      end

      segments << path unless path.empty?
      segments
    end

    def compile(segments)
      compiled = segments.map do |segment|
        case segment
        when String
          Regexp.escape(segment)
        when Symbol
          condition = @conditions[segment]
          condition = Regexp.escape(condition) unless condition.is_a?(Regexp)
          "(#{condition})"
        when Array
          "(?:#{compile(segment)})?"
        end
      end

      compiled.join
    end
    
    def captures_for(segments)
      segments.flatten.select { |s| s.is_a?(Symbol) }
    end
    
    def anchor(pattern)
      pattern
    end

    def extract_captures(data)
      captures = {}
      offsets.each do |capture, offset|
        captures[capture] = data[offset] if data[offset]
      end
      captures
    end

    def offsets
      @offsets ||= begin
        offsets = {}
        counter = 1

        captures.each do |capture|
          offsets[capture] = counter
          counter += (1 + regexp_arity(@conditions[capture]))
        end

        offsets
      end
    end

    def generate_from_segments(segments, params, defaults, optional = false)
      if optional
        # We don't want to generate all string optional segments
        return "" if segments.all? { |s| s.is_a?(String) }
        # We don't want to generate optional segments unless they are requested
        return "" if captures_for(segments).all? { |s| params[s].to_s !~ @conditions[s] }
      end
      
      generated = segments.map do |segment|
        case segment
        when String
          segment
        when Symbol
          return unless value = params[segment] || defaults[segment]
          return unless value.to_s =~ convert_to_regexp(@conditions[segment], true)
          value
        when Array
          generate_from_segments(segment, params, defaults, true) || ""
        end
      end

      # Delete any used items from the params
      segments.each { |s| params.delete(s) if s.is_a?(Symbol) }

      generated.join
    end

    # ==== UTILITIES ====

    def convert_to_regexp(item, anchor = false)
      case item
      when Array  then Regexp.new("^(?:#{item.map { |i| convert_to_regexp(i, false) }.join("|")})$")
      when Regexp then anchor ? /^#{item}$/ : item
      else Regexp.new("^#{Regexp.escape(item.to_s)}$")
      end
    end

    # Returns the number of captures for a given regular expression
    def regexp_arity(regexp)
      return 0 unless regexp.is_a?(Regexp)
      regexp.source.scan(/(?!\\)[(](?!\?[#=:!>-imx])/).length
    end    
  end
  
  class FallbackCondition < Condition
    def initialize(method_name, pattern, conditions, *)
      super(method_name, pattern, conditions, true)
    end
    
  private
  
    def anchor(pattern)
      "^#{super}$"
    end
  end

  class PathCondition < Condition
    
    register :path_info
        
    def match(request)
      super do |data|
        request.env["PATH_INFO"]   = normalize(data.post_match)
        request.env["SCRIPT_NAME"] = normalize(request.env["SCRIPT_NAME"] + data[0])
      end
    end
    
  private
    
    def anchor(pattern)
      pattern = normalize(super)
      @anchored ? "^#{pattern}$" : pattern.sub(%r'^(.*?)/*$', '^\1(?:/|$)')
    end
  
    # The URI spec states that sequential slashes is equivalent to a
    # single slash and that trailing slashes can be ignored.
    def normalize(pattern)
      "/#{pattern}".squeeze("/").sub(%r'/(.*?)/+$', '/\1')
    end
  end
end