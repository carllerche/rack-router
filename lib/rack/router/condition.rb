class Rack::Router
  SEGMENT_CHARACTERS = "[^\/.,;?]".freeze
  
  class Condition
    def self.register(type)
      @@types ||= Hash.new(FallbackCondition)
      @@types[type] = self
    end    
    
    def self.build(name, pattern, segment_conditions, anchored)
      @@types[name].new(name, pattern, segment_conditions, anchored)
    end
    
    attr_reader :segments, :captures, :pattern

    def initialize(method_name, pattern, conditions, anchored)
      @method_name  = method_name
      @segments     = []
      @captures     = {}
      @conditions   = conditions.dup
      @anchored     = anchored

      @conditions.default = /#{SEGMENT_CHARACTERS}+/
      
      if pattern.is_a?(Array) || pattern.is_a?(String)
        @segments = pattern.is_a?(Array) ? pattern : [pattern]
        @pattern  = Regexp.new(anchor(compile(@segments)))
        @captures = captures_for(@segments)
      elsif pattern.is_a?(Regexp)
        @regexp  = true
        @pattern = pattern
      else
        raise ArgumentError, "the condition pattern must be an Array (tokens), String, or Regexp"
      end
    end

    def match(request)
      if data = @pattern.match(request.send(@method_name))
        return data[0], extract_captures(data)
      end
    end
    
    def generatable?
      !@segments.nil?
    end

    def generate(params, defaults = {})
      raise "Condition cannot be generated" unless @segments
      generate_from_segments(@segments, params, defaults) or raise ArgumentError, "Condition cannot be generated with #{params.inspect}"
    end

    def inspect
      @pattern.inspect
    end

  private

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
    attr_reader :normalized_segments
    
    def initialize(*)
      super
      
      @dynamic = !@anchored || @regexp
      @normalized_segments = []
      
      # Parse the segments and normalize them for hashing
      @segments.each do |segment|
        case segment
        when String
          head, *tail = segment.split(%r'[/.,;?]+')
          if @normalized_segments.last.is_a?(String)
            @normalized_segments.last << head
          else
            tail.unshift(head) unless head == ''
          end
          @normalized_segments.concat(tail) if tail.any?
        when Symbol
          if @conditions[segment] == /#{SEGMENT_CHARACTERS}+/
            @normalized_segments << segment 
          else
            @dynamic = true
            break
          end
        else
          @dynamic = true
          break
        end
      end
    end
    
    def dynamic?
      @dynamic
    end
    
  private
    
    def anchor(pattern)
      pattern = Utils.normalize(super)
      @anchored ? "^#{pattern}$" : pattern.sub(%r'^(.*?)/*$', '^\1(?:/|$)')
    end
  end
end