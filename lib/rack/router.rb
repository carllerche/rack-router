require "rack"

module Rack
  class Router
    
    autoload :Route,     'rack/router/route'
    autoload :Condition, 'rack/router/condition'
    autoload :Builder,   'rack/router/builders'
    
    attr_reader :routes
    attr_reader :named_routes
    
    def initialize(app, options = {}, &block)
      @app          = app || fallback
      @builder      = options.delete(:builder) || Builder::Simple
      @routes       = @builder.run(options, &block)
      @named_routes = {}
      
      @routes.each do |route|
        route.compile
        @named_routes[route.name] = route if route.name
      end
    end
    
    def call(env)
      request  = Rack::Request.new(env)
      
      for route in @routes
        if args = route.match(request)
          # The routing args are destructively merged into the rack
          # environment so that they can be used by any application
          # called by the router or any app downstream.
          env.merge! "rack.route" => route, "rack.routing_args" => args
          
          # Call the application that the route points to
          result = route.app.call(env)
          
          # Return the result unless the app was not able to handle
          return result unless result[0] == 404
        end
      end
      
      @app.call(env)
    end
    
    def url(name, params = {})
      unless route = named_routes[name]
        raise ArgumentError, "Cannot find route named '#{name}'"
      end
      
      route.generate(params)
    end
    
    def end_points
      @end_points ||= @routes.map { |r| r.app }.uniq
    end
    
    def fallback
      lambda { |env| [ 404, { 'Content-Type' => 'text/html' }, "Not Found" ] }
    end
  end
end