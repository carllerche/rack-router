class Rack::Router
  class Route
    # The Rack application that the route calls when it is matched.
    #
    # :api: public
    attr_accessor :app
    
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
    end
    
    def finalize(router)
      @parent = router.mount_point
      
      raise ArgumentError, "You must specify a valid rack application" unless @app.respond_to?(:call)
      
      @request_conditions.each do |method_name, pattern|
        @request_conditions[method_name] = 
          # TODO: Refactor this ugliness
          Condition.build(method_name, pattern, segment_conditions, !@mount_point)
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
    def url(params, fallback)
      defaults = @params.merge(fallback)
      [:scheme, :host, :port, :path_info].map! do |name|
        @request_conditions[name] && @request_conditions[name].generate(params, defaults)
      end
    end
    
    # :api: private
    def shift_path_info(env, params, matched)
      new_path_info = env["PATH_INFO"].sub(/^#{Regexp.escape(matched)}/, '')
      env["SCRIPT_NAME"] = Utils.normalize(env["SCRIPT_NAME"] + matched)
      env["PATH_INFO"]   = Utils.normalize(new_path_info)
    end
    
  end
end
