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
    autoload :Utils,         'rack/router/utils'
    
    include Routable
    
    def initialize(app = nil, options = {}, &block)
      prepare(options, &block)
    end
  end
end