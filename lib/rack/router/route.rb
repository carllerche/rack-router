class Rack::Router
  class Route
    
    attr_reader   :app, :request_conditions, :segment_conditions, :params, :router
    attr_accessor :name
    
    def initialize(app, request_conditions, segment_conditions, params, mount_point = true)
      @app                = app
      @request_conditions = request_conditions
      @segment_conditions = segment_conditions
      @params             = params
      @mount_point        = mount_point
      
      # For route generation only
      # TODO: Move this into Routable
      if mount_point?
        @app.mount_at(self)
      end
      
      raise ArgumentError, "You must specify a valid rack application" unless app.respond_to?(:call)
    end
    
    def compile(router)
      @router = router
      
      @request_conditions.each do |method_name, pattern|
        @request_conditions[method_name] = 
          # TODO: Refactor this ugliness
          Condition.build(method_name, pattern, segment_conditions, !(mount_point? || @mount_point))
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
    def handle(request, env)
      params = @params.dup
      path_info, script_name = env["PATH_INFO"], env["SCRIPT_NAME"]
      
      return unless request_conditions.all? do |method_name, condition|
        next true unless request.respond_to?(method_name)
        (captures = condition.match(request)) && params.merge!(captures)
      end
      
      env["rack_router.router"] = self
      env["rack_router.params"].merge! params
      
      @app.call(env)
    ensure
      env["PATH_INFO"], env["SCRIPT_NAME"] = path_info, script_name
    end
    
    # Generates a URI from the route given the passed parameters
    # ====
    def generate(params)
      query_params = params.dup
      
      # Condition#generate will delete from the hash any params that it uses
      # that way, we can just append whatever is left to the query string
      uri = generate_path(query_params)
      
      query_params.delete_if { |k, v| v.nil? }
      
      uri << "?#{Rack::Utils.build_query(query_params)}" if query_params.any?
      uri
    end
    
  protected
  
    def generate_path(params)
      path = ""
      path << router.mount_point.generate_path(params) if router.mounted?
      path << @request_conditions[:path_info].generate(params, @params) if @request_conditions[:path_info]
      path
    end
    
  end
end
