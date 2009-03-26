class Rack::Router
  module Routable
    
    def routes
      @routes ||= []
    end
    
    def named_routes
      @named_routes ||= {}
    end
    
    def prepare(options = {}, &block)
      builder = options.delete(:builder) || Builder::Simple
      @routes = builder.run(options, &block)
      @named_routes = {}
      
      @routes.each do |route|
        route.compile
        @named_routes[route.name] = route if route.name
      end
      
      self
    end
    
    # TODO: Figure out the API of this method
    def route(env)
      request  = Rack::Request.new(env)
      
      for route in routes
        if args = route.match(request)
          # The routing args are destructively merged into the rack
          # environment so that they can be used by any application
          # called by the router or any app downstream.
          env.merge! "rack.route" => route, "rack.routing_args" => args
          
          return true, nil unless route.app
          
          # Call the application that the route points to
          result = route.app.call(env)
          
          # Return the result unless the app was not able to handle
          return true, result unless result[0] == 404
        end
      end
      
      return false, nil
    end
    
    def url(name, params = {})
      unless route = named_routes[name]
        raise ArgumentError, "Cannot find route named '#{name}'"
      end
      
      route.generate(params)
    end
    
  end
end