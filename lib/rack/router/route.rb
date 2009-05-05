class Rack::Router
  class Route
    # The Rack application that the route calls when it is matched.
    #
    # :api: public
    attr_reader :app
    
    # The string that env['PATH_INFO'] gets set to before calling the app
    # when the route is matched.
    #
    # ==== Formats
    # "/simple/path"   The string literal is what env["PATH_INFO"] gets set
    #                  to.
    # "/with/:capture" The placeholder gets replaced with the associated value
    #                  in the captures extracted from the request by the route.
    # nil              Whatever remains in the current env["PATH_INFO"] after
    #                  the matched portion has been removed. This could be an
    #                  empty string.
    #
    # :api: public
    attr_reader :path_info
    
    # A Hash containing the conditions that are used to match the route against
    # the request. The keys are the request method names, the values are the
    # conditions.
    #
    # :api: public
    attr_reader :request_conditions
    
    
    # A Hash containing conditions to use for each dynamic segment.
    #
    # :api: public
    attr_reader :segment_conditions
    
    # A Hash containing default rack_router.params to use when the route
    # is matched. Any parameter extracted from the request takes
    # precedence over the ones specified here.
    #
    # :api: public
    attr_reader :params
    
    # The Routable object that owns this route.
    #
    # :api: public
    attr_reader :router
    
    # :api: private
    attr_reader :http_methods
    
    # Symbol representing the name of the route. This name can be used
    # to look up the route.
    #
    # :api: public
    attr_accessor :name
    
    # Initializes a new route. This should only be used by the Builder classes.
    #
    # ==== Parameters
    # app<#call>::
    # path_info<String>::
    # request_conditions<Hash>::
    # segment_conditions<Hash>::
    # params<Hash>::
    # mount_point<Boolean>::
    #
    # :api: plugin
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
    
    def finalize(router)
      @router = router
      
      @request_conditions.each do |method_name, pattern|
        @request_conditions[method_name] = 
          # TODO: Refactor this ugliness
          Condition.build(method_name, pattern, segment_conditions, !(mount_point? || @mount_point))
      end
      
      # Figure out the HTTP methods that this route can respond to
      @http_methods = []
      condition     = request_conditions[:request_method]
      %w(GET POST PUT DELETE HEAD).each do |method|
        @http_methods << method if !condition || condition.pattern =~ method
      end
      
      # Once the route is compiled, we don't want to be able to modify it any further.
      freeze
    end
    
    def keys
      @keys ||= [@request_conditions.map { |c| c.captures }, @params.keys].flatten.uniq
    end
    
    def path_info
      @request_conditions[:path_info]
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
        matched, captures = condition.match(request)
        if matched
          params.merge!(captures)
          if method_name == :path_info
            shift_path_info(env, params, matched) 
          end
          true
        end
      end
      
      env["rack_router.route"] = self
      env["rack_router.params"].merge! params
      
      @app.call(env)
    ensure
      env["PATH_INFO"], env["SCRIPT_NAME"] = path_info, script_name
    end
    
    # Generates a URI from the route given the passed parameters
    # ====
    def generate(params, fallback)
      query_params = params.dup
      
      # Condition#generate will delete from the hash any params that it uses
      # that way, we can just append whatever is left to the query string
      uri = generate_path(query_params, fallback)
      
      query_params.delete_if { |k, v| v.nil? }
      
      uri << "?#{Rack::Utils.build_query(query_params)}" if query_params.any?
      uri
    end
    
    # :api: private
    def shift_path_info(env, params, matched)
      new_path_info = env["PATH_INFO"].sub(/^#{Regexp.escape(matched)}/, '')
      env["SCRIPT_NAME"] = Utils.normalize(env["SCRIPT_NAME"] + matched)
      env["PATH_INFO"]   = Utils.normalize(new_path_info)
    end
    
  protected
  
    def generate_path(params, fallback)
      path = ""
      path << router.mount_point.generate_path(params, fallback) if router.mounted?
      path << @request_conditions[:path_info].generate(params, @params.merge(fallback)) if @request_conditions[:path_info]
      path
    end
    
  end
end
