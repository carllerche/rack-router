class Rack::Router
  # Mixin that can be used by any Rack application to provide routing
  # to any number of child rack applications.
  #
  # Features:
  # ---
  # * Set conditions on any method provided by the request object
  # * Rewrite the request before passing it to the child rack application
  # * Mount any number of child router objects inside a parent.
  module Routable
    
    attr_reader :routes, :named_routes, :mount_point
    
    def prepare(options = {}, &block)
      builder       = options.delete(:builder) || Builder::Simple
      @dependencies = options.delete(:dependencies) || {}
      @root         = self
      @route_sets   = {}
      @named_routes = {}
      @mounted_apps = {}
      @routes = builder.run(options, &block)
      
      %w(GET POST PUT DELETE HEAD).each do |method|
        @route_sets[method] = RouteSet.new
      end
      
      compile
      
      # Set the root of the router tree for each router
      descendants.each { |d| d.root = self }
      
      self
    end
    
    def call(env)
      env["rack_router.params"] ||= {}
      
      route_set = @route_sets[env["REQUEST_METHOD"]]
      env["PATH_INFO"].scan(/#{SEGMENT_CHARACTERS}+/) do |s|
        route_set = route_set[s]
      end
      route_set.handle(Rack::Request.new(env), env)
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
  
    def compile
      @routes.each do |route|
        # Compile the route
        route.compile(self)
        
        # Add the route to the appropriate route set
        route.http_methods.each do |method|
          @route_sets[method] << route
        end
      
        # Add the route to 
        if route.name
          route.mount_point? ?
            @mounted_apps[route.name] = route.app :
            @named_routes[route.name] = route
        end
      end
    end
    
    # TODO: A thought occurs... method_missing is slow.
    # ---
    # Yeah, optimizations can come later. kthxbai
    def method_missing(name, *args)
      @mounted_apps[name] || super
    end
    
  end
end
