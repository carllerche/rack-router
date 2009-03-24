class Rack::Router::Builder
  class Simple
    
    def self.run(options = {})
      builder = new
      yield builder
      builder.routes
    end
    
    attr_reader :routes
    
    def initialize
      @routes = []
    end
    
    def map(path, options = {})
      @routes << Rack::Router::Route.new(options[:to], { :path_info => path }, options[:with])
    end
    
  end
end