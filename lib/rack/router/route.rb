class Rack::Router
  class Route
    
    attr_reader   :app, :request_conditions, :segment_conditions, :params, :router
    attr_accessor :name
    
    def initialize(app, request_conditions, segment_conditions, params)
      @app                = app
      @request_conditions = request_conditions
      @segment_conditions = segment_conditions
      @params             = params
      
      # TODO: Temporary hack to get simple path prefixing working
      if mount_point?
        raise MountError, "#{@app} has already been mounted" if @app.mounted?
        @app.mount_point = self
        @path_prefix  = request_conditions[:path_info].to_s
      end
      
      raise ArgumentError, "You must specify a valid rack application" unless app.respond_to?(:call)
    end
    
    def compile(router)
      @router = router
      
      @request_conditions.each do |method_name, pattern|
        @request_conditions[method_name] = method_name == :path_info ?
          PathCondition.new(pattern, segment_conditions) :
          Condition.new(pattern, segment_conditions)
      end
      
      freeze
    end
    
    def keys
      @keys ||= [@request_conditions.map { |c| c.captures }, @params.keys].flatten.uniq
    end
    
    # Determines whether or not the current route is a mount point to a child
    # router.
    def mount_point?
      @app.is_a?(Routable)
    end
    
    # Handles the given request. If the route matches the request, it will
    # dispatch to the associated rack application.
    #
    # TODO: Try to refactor this so that there is less duplication
    def handle(request, path_prefix)
      if mount_point?
        # Make sure that all the conditions are satisfied except for path_info
        return nil, {}, nil unless request_conditions.all? do |method_name, condition|
          next true unless request.respond_to?(method_name)
          method_name == :path_info || condition.match(request.send(method_name))
        end
        
        # TODO: Refactor the hax
        path_prefix << @path_prefix
        
        # The route points to a child router, so defer routing to the
        # child by calling it's handle method and passing in the current
        # path_prefix.
        return @app.handle(request.env, path_prefix)
      else
        params = @params.dup
        
        # Next, try matching the current route.
        return nil, {}, nil unless request_conditions.all? do |method_name, condition|
          next true unless request.respond_to?(method_name)
          capts = condition.match(request.send(method_name), method_name == :path_info && path_prefix) and params.merge!(capts)
        end
        
        env = request.env.merge "rack.route" => self, "rack.routing_args" => params
        
        result = @app.call(env)
        
        return result[0] != 404 && self, params, result
      end
    end
    
    # Generates a URI from the route given the passed parameters
    # ====
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