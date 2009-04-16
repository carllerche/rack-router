require "rack"

module Rack
  # Rack::Router is a simple class that includes Rack::Router::Routable.
  # It can be used as middleware and can provide all the features needed
  # to setup routing to any number of child rack applications.
  #
  # For more information, refer to Rack::Router::Routable
  class Router
    
    class MountError < StandardError ; end
    
    # The status header that is set to indicate the status of any child
    # router object. This is basically whether or not a route has been
    # matched or not.
    STATUS_HEADER = "X-Rack-Router-Status"
    
    # The status message that is used to indicate that no route has been
    # matched.
    NOT_FOUND = "404 Not Found"
    
    # A full rack response that is used to indicate that no route was matched.
    # Routable middleware will return this rack response after attempting to
    # match the passed env against it's routes.
    NOT_FOUND_RESPONSE = [ 404, { STATUS_HEADER => NOT_FOUND }, [NOT_FOUND] ]
    
    require 'rack/router/routable'
    require 'rack/router/route'
    require 'rack/router/route_set'
    require 'rack/router/condition'
    require 'rack/router/parsing'
    require 'rack/router/builders'
    require 'rack/router/utils'
    
    include Routable
    
    def initialize(app = nil, options = {}, &block)
      prepare(options, &block)
    end
  end
end