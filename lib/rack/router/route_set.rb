class Rack::Router
  # TODO: Refactor this file so that it is better organized
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
    
    def compile
      compile_handling
    end
  end
  
  class RouteSet < Hash
    include Handling
    
    attr_reader :routes
    
    def initialize(routes = [], depth = 0)
      super(DynamicSet.new(routes))
      @depth    = depth
      @routes   = routes.dup  # All routes at this level or deeper
    end
    
    def <<(route)
      if dynamic_for_depth?(route)
        add_route(route)
        add_default_route(route)
      elsif key_for(route).is_a?(Symbol)
        add_default_route(route)
      elsif key = key_for(route)
        self[key] = new_sub_set(key) unless has_key?(key)
        self[key] << route
      else
        add_route(route)
      end
      
      route
    end
    
    def compile
      compile_handling
      default.compile
      values.each { |set| set.compile }
    end
    
  private
  
    def add_route(route)
      @routes << route unless @routes.include?(route)
      route
    end
    
    def add_default_route(route)
      default << route
      values.each { |set| set << route }
      route
    end
    
    def dynamic_for_depth?(route, depth = @depth)
      !route.path_info || (key_for(route, depth).nil? && route.path_info.dynamic?)
    end
    
    def key_for(route, depth = @depth)
      route.path_info && route.path_info.normalized_segments[depth]
    end
    
    def new_sub_set(key)
      routes = default.routes.select { |route| for_child?(route, key) }
      RouteSet.new(routes, @depth + 1)
    end
  
    def for_child?(route, key)
      # If the route is dynamic, it gets added
      return true if dynamic_for_depth?(route)
      
      if dynamic_for_depth?(route, @depth + 1)
        route_key = key_for(route, @depth)
        return true if route_key.is_a?(Symbol) || route_key == key
      end
    end
  end
end