class Rack::Router
  class RouteSet < Hash
    
    def initialize(dynamic_routes = [], depth = 0)
      super(self)
      @depth  = depth
      @routes = []
    end
    
    def <<(route)
      if key = key_for(route)
        self[key] = RouteSet.new([], @depth + 1) if self[key] == self
        self[key] << route
      else
        @routes << route
      end
      
      route
    end
    
    def handle(request, env)
      for route in @routes
        response = route.handle(request, env)
        return response if response && handled?(response)
      end
      
      NOT_FOUND_RESPONSE
    end
    
  private
  
    def leaf?
      default == self
    end
  
    def handled?(response)
      response[1][STATUS_HEADER] != NOT_FOUND
    end
    
    def key_for(route)
      route.path_info && route.path_info.normalized_segments[@depth]
    end
  
  end
end