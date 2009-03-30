class Rack::Router
  module Routable
    
    attr_accessor :mount_point
    
    def prepare(options = {}, &block)
      builder = options.delete(:builder) || Builder::Simple
      @routes = builder.run(options, &block)
      @named_routes = {}
      
      @routes.each do |route|
        route.compile(self)
        @named_routes[route.name] = route if route.name
      end
      
      self
    end
    
    def call(env)
      path_prefix = env["rack_router.path_prefix"] || ""
      request     = Rack::Request.new(env)
      
      for route in routes
        response = route.handle(request, path_prefix)
        return response if response && handled?(response)
      end
      
      NOT_FOUND_RESPONSE
    end
    
    private
    def handled?(response)
      response[1][STATUS_HEADER] != NOT_FOUND_RESPONSE
    end
    
    public
    
    def url(name, params = {})
      route = _named_routes[name]
      
      # Search up the router chain
      unless route
        router = self
        while !route && (router = router.parent)
          route = router._named_routes[name]
        end
      end
      
      raise ArgumentError, "Cannot find route named '#{name}'" unless route
      
      route.generate(params)
    end
    
    def routes
      @routes ||= []
    end
    
    def named_routes
      @named_routes ||= {}
    end
    
    def mounted?
      mount_point
    end
    
    def parent
      mounted? && mount_point.router
    end
    
    def children
      @routes.map { |r| r.app if r.mount_point? }.compact
    end
    
    def end_points
      @end_points ||= @routes.map { |r| r.app unless r.mount_point? }.compact.uniq
    end
    
  protected
  
    def _named_routes
      @_named_routes ||= begin
        _named_routes = {}
        children.reverse.each do |c|
          _named_routes.merge! c._named_routes
        end
        _named_routes.merge! @named_routes
      end
    end
    
  end
end