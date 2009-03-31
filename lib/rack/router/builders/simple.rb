class Rack::Router::Builder
  class Simple
    
    # Route format:
    # ---
    # :scheme :// :subdomain . :domain / :path
    # { :scheme => :scheme, :host => :host, :subdomain => :subdomain, :domain => :domain, :path => :path }
    def self.run(options = {})
      builder = new
      yield builder
      builder.routes
    end
    
    attr_reader :routes
    
    def initialize
      @routes = []
    end
    
    def map(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      
      path   = args[0]
      method = args[1]
      
      conditions                  = options[:conditions] || {}
      conditions[:path_info]      = path if path
      conditions[:request_method] = upcase_method(method) if method
      
      route = Rack::Router::Route.new(options[:to], conditions.reject { |k,v| k == :id }, conditions.dup, options[:with] || {}, options[:anchor])
      route.name = options[:name].to_sym if options[:name]
      
      @routes << route
    end
    
  private
  
    def upcase_method(method)
      case method
      when String, Symbol then method.to_s.upcase
      when Array          then method.map { |m| upcase_method(m) }
      else "GET"
      end
    end
    
  end
end