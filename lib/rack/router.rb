require "rack/request"

module Rack
  class Router
    
    autoload :Route,     'rack/router/route'
    autoload :Condition, 'rack/router/condition'
    autoload :Builder,   'rack/router/builders'
    
    def initialize(app, options = {}, &block)
      @app     = app || lambda { |env| [ 404, { 'Content-Type' => 'text/html' }, "Not Found" ] }
      @builder = options.delete(:builder) || Builder::Simple
      @routes  = @builder.run(options, &block)
      
      @routes.each { |route| route.compile }
    end
    
    def call(env)
      for route in @routes
        if args = route.match(env)
          # The routing args are destructively merged into the rack
          # environment so that they can be used by any application
          # called by the router or any app downstream.
          env.merge! "rack.routing_args" => args
          
          # Call the application that the route points to
          result = route.app.call(env)
          
          # Return the result unless the app was not able to handle
          return result unless result[0] == 404
        end
      end
      
      @app.call(env)
    end
  end
end