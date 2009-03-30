require "rack"

module Rack
  class Router
    
    class MountError < StandardError ; end
    
    STATUS_HEADER      = "X-Rack-Router-Status"
    NOT_FOUND          = "404 Not Found"
    NOT_FOUND_RESPONSE = [ 404, { STATUS_HEADER => NOT_FOUND }, NOT_FOUND ]
    
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
      resp = super
      
      handled?(resp) ? resp : fallback.call(env)
    end
    
    def fallback
      lambda { |env| [ 404, { 'Content-Type' => 'text/html' }, "Not Found" ] }
    end
  end
end