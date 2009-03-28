require "rack"

module Rack
  class Router
    
    class MountError < StandardError ; end
    
    autoload :Routable,      'rack/router/routable'
    autoload :Route,         'rack/router/route'
    autoload :Condition,     'rack/router/condition'
    autoload :PathCondition, 'rack/router/condition'
    autoload :Builder,       'rack/router/builders'
    
    include Routable
    
    def initialize(app = nil, options = {}, &block)
      @app = app || fallback
      
      prepare(options, &block)
    end
    
    def call(env)
      route, params, response = handle(env)
      response || @app.call(env)
    end
    
    def fallback
      lambda { |env| [ 404, { 'Content-Type' => 'text/html' }, "Not Found" ] }
    end
  end
end