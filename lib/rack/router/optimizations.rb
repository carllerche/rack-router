class Rack::Router
  module Optimizations
    module Condition
    
      def condition_statement
        "c_#{@method_name} =~ #{@pattern.inspect} && (#{compiled_captures};true)"
      end
      
      def capture_statements
        captures.map { |capture| ":#{capture} => p_#{capture}" }
      end
    
    private

      # Returns the instance singleton
      def singleton
        (class << self ; self ; end)
      end
    
      # ==== Route Recognition ====
      def compiled_captures
        c = offsets.map { |capture, i| "p_#{capture} = $#{i}" }
        c << "matched_path_info = $&" if @method_name == :path_info
        c.join(';')
      end
    
      # ==== Route Generation ====
      def compile
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

    module Route
      
      def compiled_statement(index)
        return <<-STATEMENT
          if #{condition_statements}
            route = @routes[#{index}]
            #{params_extraction}
            #{path_info_shifting}
            #{yield}
          end
        STATEMENT
      end
      
    private
    
      def condition_statements
        return "true" if request_conditions.empty?
        request_conditions.map { |k,v| v.condition_statement }.join(' && ')
      end
      
      def params_extraction
        statements = request_conditions.map { |k,c| c.capture_statements }.flatten.join(', ')
        "params = env['rack_router.params'] = route.params.merge({#{statements}})"
      end
      
      def path_info_shifting
        "route.shift_path_info(env, params, matched_path_info)" if request_conditions[:path_info]
      end
    end
  end
end