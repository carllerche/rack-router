class Rack::Router
  class Route
    
    attr_reader   :app, :conditions, :params
    attr_accessor :name
    
    def initialize(app, conditions, params)
      @app, @conditions, @params = app, conditions, params
    end
    
    def match(env)
      request = Rack::Request.new(env)
      conditions.all? { |k, v| request.send(k) == v } && @params
    end
    
  end
end