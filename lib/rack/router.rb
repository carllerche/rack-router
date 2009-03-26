require "rack"

module Rack
  class Router
    
    autoload :Routable,  'rack/router/routable'
    autoload :Route,     'rack/router/route'
    autoload :Condition, 'rack/router/condition'
    autoload :Builder,   'rack/router/builders'
    
    include Routable
    
    def initialize(app = nil, options = {}, &block)
      @app = app || fallback
      
      prepare(options, &block)
    end
    
    def call(env)
      matched, response = route(env)
      response || @app.call(env)
    end
    
    def end_points
      @end_points ||= @routes.map { |r| r.app }.uniq
    end
    
    def fallback
      lambda { |env| [ 404, { 'Content-Type' => 'text/html' }, "Not Found" ] }
    end
  end
end