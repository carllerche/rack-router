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

    attr_reader :routes, :named_routes

    def prepare(options = {}, &block)
      builder       = options.delete(:builder) || Builder::Simple
      @named_routes = {}
      @routes       = []

      builder.run(options, &block).each do |route|
        prepare_route(route)
      end

      finalize

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

  private

    def prepare_route(route)
      @routes << route
      
      route.finalize(self)

      if route.name
        @named_routes[route.name] = route
      end
    end

    def finalize
      # Implemented in optimizations
    end
  end
end
