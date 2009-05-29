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
      @mount_point  = options.delete(:mount_point)
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
      query_params = params.dup

      raise ArgumentError, "Cannot find route named '#{name}'" unless route

      # Condition#generate will delete from the hash any params that it uses
      # that way, we can just append whatever is left to the query string
      parts = route.url(query_params, fallback)
      
      url = ""
      if parts[0] || parts[1] || parts[2]
        url << (parts[0] || "http") << "://"
        url << parts[1]
        url << ":#{parts[2]}" if parts[2] && parts[2] != 80
      end
      
      url << URI.escape(parts[3])
      
      query_params.delete_if { |k, v| v.nil? }

      url << "?#{Rack::Utils.build_query(query_params)}" if query_params.any?
      url
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
