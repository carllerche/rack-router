require "rack/request"

module Rack
  class Router
    
    autoload :Route,   'rack/router/route'
    autoload :Builder, 'rack/router/builders'
    
    def initialize(app, options = {}, &block)
      @app     = app || lambda { |env| [ 404, { 'Content-Type' => 'text/html' }, "Not Found" ] }
      @builder = options.delete(:builder) || Builder::Simple
      @routes  = @builder.run(options, &block)
    end
    
    def call(env)
      for route in @routes
        if route.matches?(env)
          result = route.app.call(env)
          return result unless result[0] == 404
        end
      end
      
      @app.call(env)
    end
  end
end