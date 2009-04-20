class Rack::Router
  module ConditionOptimizations
    
    def initialize(*)
      compile_generation
    end
    
  private

    # Returns the instance singleton
    def singleton
      (class << self ; self ; end)
    end
    
    def compile_generation
      singleton.class_eval <<-EVAL, __FILE__, __LINE__ + 1
        def generate(params, defaults = {})
          raise ArgumentError, "Condition cannot be generated" unless @segments
          #{generation_requirement}
          "#{compiled_segments(@segments)}"
        end
      EVAL
    end
    
    def generation_requirement
      if @segments.any? { |s| s.is_a?(Symbol) }
        ruby = <<-EVAL
          unless #{segment_requirement(@segments)}
            raise ArgumentError, "Condition cannot be generated with \#{params.inspect}"
          end
        EVAL
      end
    end
    
    def segment_requirement(segments)
      captures = segments.select { |s| s.is_a?(Symbol) }
      captures.map do |s|
        condition = convert_to_regexp(@conditions[s], true)
        "(v_#{s} = (params[:#{s}] || defaults[:#{s}]).to_s) =~ #{condition.inspect}"
      end.join(' && ')
    end
    
    def compiled_segments(segments, optionals = false)
      # Do nothing if all the segments are strings
      return if optionals && segments.flatten.all? { |s| s.is_a?(String) }
      
      segments.map do |segment|
        case segment
        when String
          segment
        when Symbol
          # Delete the segment from the params hash and return it
          "\#{params.delete(:#{segment}) ; v_#{segment}}"
        when Array
          captures = captures_for(segment)
          if captures.any?
            "\#{if (#{captures.map{|c|"params[:#{c}]"}.join(' || ')}) && #{segment_requirement(segment)} ; \"#{compiled_segments(segment, true)}\" ; end}"
          else
            compiled_segments(segment, true)
          end
        end
      end.join
    end
  end
end