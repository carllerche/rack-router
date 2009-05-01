class Rack::Router
  # An optimized way to store routes for quicker lookup
  require 'rack/router/route_set'
  
  class Condition
    def condition_statement
      "c_#{@method_name} =~ #{@pattern.inspect} && (#{compiled_captures};true)"
    end
    
    def capture_statements
      captures.map { |capture| ":#{capture} => p_#{capture}" }
    end
    
    def compile
      singleton.class_eval <<-EVAL, __FILE__, __LINE__ + 1
        def generate(params, defaults = {})
          raise ArgumentError, "Condition cannot be generated" unless @segments
          #{generation_requirement}
          "#{compiled_segments(@segments)}"
        end
      EVAL
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
  
  class Route
    def compiled_statement(index)
      return <<-STATEMENT
        if #{condition_statements}
          route = @routes[#{index}]
          #{params_extraction}
          #{path_info_shifting}
          env['rack_router.params'].merge!(params)
          #{yield}
          env['PATH_INFO'], env['SCRIPT_NAME'] = o_path_info, o_script_name
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
      "params = route.params.merge({#{statements}}.reject{|k,v| v.nil?})"
    end
    
    def path_info_shifting
      "route.shift_path_info(env, params, matched_path_info)" if request_conditions[:path_info]
    end
  end
  
  module Handling
    def compile_handling
      (class << self ; self ; end).class_eval <<-EVAL, __FILE__, __LINE__+1
        def handle(request, env)
          #{compiled_statement}
          NOT_FOUND_RESPONSE
        end
      EVAL
    end
    
  private
  
    def compiled_statement
      keys, body = [], ""
      
      @routes.each_with_index do |route, i|
        keys.concat route.request_conditions.keys
        
        body << route.compiled_statement(i) do
          <<-STATEMENT
            resp = route.app.call(env)
            return resp if resp && handled?(resp)
          STATEMENT
        end
      end
      
      keys.uniq!
      head = keys.map! { |k| "c_#{k} = request.#{k}" }.join(';')
      
      path_info = "o_path_info, o_script_name = env['PATH_INFO'], env['SCRIPT_NAME']"
    
      "#{head}\n#{path_info}\n#{body}"
    end
  end
  
  module Routable
    def call(env)
      env["rack_router.params"] ||= {}
      
      route_set = @route_sets[env["REQUEST_METHOD"]]
      env["PATH_INFO"].scan(/#{SEGMENT_CHARACTERS}+/) do |s|
        route_set = route_set[s]
      end
      route_set.handle(Rack::Request.new(env), env)
    end
    
  private
  
    def finalize
      @route_sets = {}
      
      %w(GET POST PUT DELETE HEAD).each do |method|
        @route_sets[method] = RouteSet.new
      end
      
      @routes.each do |route|
        route.request_conditions.each do |k, v|
          v.compile
        end
        # Add the route to the appropriate route set
        route.http_methods.each do |method|
          @route_sets[method] << route
        end
      end
      
      @route_sets.each { |k,v| v.compile }
    end
  end
end