class Rack::Router
  
  module Handling
    def handle(request, env)
      for route in @routes
        response = route.handle(request, env)
        return response if response && handled?(response)
      end
      
      NOT_FOUND_RESPONSE
    end
  private
    def handled?(response)
      response[1][STATUS_HEADER] != NOT_FOUND
    end
  end
  
  class DynamicSet < Hash
    
    include Handling
    
    attr_reader :routes
    
    def initialize(routes)
      super(self)
      @routes = routes.dup
    end
    
    def <<(route)
      @routes << route unless @routes.include?(route)
      route
    end
  end
  
  class RouteSet < Hash
    
    include Handling
    
    attr_reader :routes
    
    def initialize(routes = [], depth = 0)
      super(DynamicSet.new(routes))
      @depth    = depth
      @routes   = routes.dup  # All routes at this level or deeper
      @children = routes.dup  # All routes at this level (including dynamics)
    end
    
    def <<(route)
      @children << route unless @children.include?(route) # Track the route
      
      if dynamic_for_depth?(route) || key_for(route).is_a?(Symbol)
        @routes << route unless @routes.include?(route)
        default << route
        values.each { |set| set << route }
      elsif key = key_for(route)
        self[key] = new_sub_set(key) if self[key] == self
        self[key] << route
      else
        @routes << route unless @routes.include?(route)
      end
      
      route
    end
    
  private
    
    def dynamic_for_depth?(route, depth = @depth)
      !route.path_info || (key_for(route, depth).nil? && route.path_info.dynamic?)
    end
    
    def key_for(route, depth = @depth)
      route.path_info && route.path_info.normalized_segments[depth]
    end
    
    def new_sub_set(key)
      children = @children.select { |route| for_child?(route, key) }
      RouteSet.new(children, @depth + 1)
    end
  
    def for_child?(route, key)
      return true if dynamic_for_depth?(route) && dynamic_for_depth?(route, @depth + 1)
      if dynamic_for_depth?(route, @depth + 1)
        next_key = key_for(route, @depth + 1)
        return true if next_key.is_a?(Symbol) || next_key == key
      end
    end
  end
end