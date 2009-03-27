class Rack::Router
  class Route
    
    attr_reader   :app, :request_conditions, :segment_conditions, :params
    attr_accessor :name
    
    def initialize(app, request_conditions, segment_conditions, params)
      @app                = app
      @request_conditions = request_conditions
      @segment_conditions = segment_conditions
      @params             = params
      
      raise ArgumentError, "You must specify a valid rack application" unless app.respond_to?(:call)
    end
    
    def compile
      @request_conditions.each do |k, pattern|
        @request_conditions[k] = Condition.new(pattern, segment_conditions)
      end
      
      freeze
    end
    
    def keys
      @keys ||= [@request_conditions.map { |c| c.captures }, @params.keys].flatten.uniq
    end
    
    def mount_point?
      @app.is_a?(Routable)
    end
    
    def handle(request, context = nil)
      if mount_point?
        # Do something that involves matching a child app
        raise NotImplementedError
      else
        params = @params.dup
        
        return nil, {}, nil unless request_conditions.all? do |method_name, condition|
          next true unless request.respond_to?(method_name)
          capts = condition.match(request.send(method_name)) and params.merge!(capts)
        end
        
        return self, params, nil unless @app
        
        env = request.env.merge "rack.route" => self, "rack.routing_args" => params
        
        result = @app.call(env)
        
        return result[0] != 404 && self, params, result
      end
    end
    
    def generate(params)
      query_params = params.dup
      # Condition#generate will delete from the hash any params that it uses
      # that way, we can just append whatever is left to the query string
      uri  = @request_conditions[:path_info].generate(query_params)
      uri << "?#{Rack::Utils.build_query(query_params)}" if query_params.any?
      uri
    end
    
  end
end