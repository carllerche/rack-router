class Rack::Router
  module Routable
    
    attr_accessor :mount_point
    attr_reader :routes, :named_routes
    
    def prepare(options = {}, &block)
      builder = options.delete(:builder) || Builder::Simple
      @routes = builder.run(options, &block)
      @named_routes = {}
      @mounted_apps = {}
      
      @routes.each do |route|
        route.compile(self)
        if route.name
          route.mount_point? ?
            @mounted_apps[route.name] = route.app :
            @named_routes[route.name] = route
        end
      end
      
      self
    end
    
    def call(env)
      request = Rack::Request.new(env)
      
      for route in routes
        response = route.handle(request, env)
        return response if response && handled?(response)
      end
      
      NOT_FOUND_RESPONSE
    end
    
    def url(name, params = {})
      route = named_routes[name]
      
      raise ArgumentError, "Cannot find route named '#{name}'" unless route
      
      route.generate(params)
    end
    
    def mounted?
      mount_point
    end
    
  private
  
    def handled?(response)
      response[1][STATUS_HEADER] != NOT_FOUND
    end
    
    # TODO: A thought occurs... method_missing is slow.
    # ---
    # Yeah, optimizations can come later. kthxbai
    def method_missing(name, *args)
      @mounted_apps[name] || super
    end
    
  end
end