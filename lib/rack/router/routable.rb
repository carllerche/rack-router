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
    include Handling

    attr_reader :routes, :named_routes, :mount_point

    def prepare(options = {}, &block)
      builder       = options.delete(:builder) || Builder::Simple
      @dependencies = options.delete(:dependencies) || {}
      @root         = self
      @named_routes = {}
      @mounted_apps = {}
      @routes       = []

      builder.run(options, &block).each do |route|
        prepare_route(route)
      end

      finalize

      # Set the root of the router tree for each router
      descendants.each { |d| d.root = self }

      self
    end

    def call(env)
      env["rack_router.params"] ||= {}
      
      handle(Rack::Request.new(env), env)
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

    def prepare_route(route)
      @routes << route
      
      route.finalize(self)

      if route.name
        route.mount_point? ?
          @mounted_apps[route.name] = route.app :
          @named_routes[route.name] = route
      end
    end

    def finalize
      # @route_sets.each { |k,v| v.compile }
    end

    # TODO: A thought occurs... method_missing is slow.
    # ---
    # Yeah, optimizations can come later. kthxbai
    def method_missing(name, *args)
      @mounted_apps[name] || super
    end
  end
end
