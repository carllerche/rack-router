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
      params = @params.dup
      env    = request.env
      
      return unless request_conditions.all? do |method_name, condition|
        next true unless request.respond_to?(method_name)
        captures = condition.match(request.send(method_name))
        captures && params.merge!(captures)
      end
      
      env.merge! "rack_router.route" => self, "rack_router.params" => params
      
      @app.call(env)
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