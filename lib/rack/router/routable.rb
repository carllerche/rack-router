class Rack::Router
  module Routable
    
    attr_reader :routes, :named_routes, :mount_point
    
    def prepare(options = {}, &block)
      builder       = options.delete(:builder) || Builder::Simple
      @dependencies = options.delete(:dependencies) || {}
      @root         = self
      @named_routes = {}
      @mounted_apps = {}
      @routes = builder.run(options, &block)
      
      @routes.each do |route|
        route.compile(self)
        if route.name
          route.mount_point? ?
            @mounted_apps[route.name] = route.app :
            @named_routes[route.name] = route
        end
      end
      
      # Set the root of the router tree for each router
      descendants.each { |d| d.root = self }
      
      self
    end
    
    def call(env)
      request = Rack::Request.new(env)
      
      env["rack_router.params"] ||= {}
      
      for route in routes
        response = route.handle(request, env)
        return response if response && handled?(response)
      end
      
      NOT_FOUND_RESPONSE
    end
    
    def url(name, params = {}, fallback = {})
      route = named_routes[name]
      
      raise ArgumentError, "Cannot find route named '#{name}'" unless route
      
      route.generate(params, fallback)
    end

    def mount_at(mount_point)
      raise MountError, "#{self} has already been mounted" if mounted?
      @mount_point = mount_point
    end
    
    def mounted?
      mount_point
    end
    
  protected
  
    def dependencies
      @dependencies
    end
    
    def children
      @children ||= routes.map { |r| r.app if r.mount_point? }.compact
    end
    
    def descendants
      @descendants ||= [ children, children.map { |c| c.descendants } ].flatten
    end
    
    def root=(router)
      @dependencies.each do |klass, name|
        if dependency = router.descendants.detect { |r| r.is_a?(klass) || r == klass }
          @mounted_apps[name] ||= dependency
        end
      end
      
      @root = router
    end
    
  private
  
    def handled?(response)
      response[1][STATUS_HEADER] != NOT_FOUND
    end
    
    # TODO: A thought occurs... method_missing is slow.
    # ---
    # Yeah, optimizations can come later. kthxbai
    def method_missing(name, *args)
      @mounted_apps[name] || super
    end
    
  end
end
