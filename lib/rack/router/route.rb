class Rack::Router
  class Route
    
    attr_reader   :app, :conditions, :params
    attr_accessor :name
    
    def initialize(app, conditions, params)
      @app, @conditions, @params = app, conditions, params
    end
    
    def compile
      @conditions.each do |k, v|
        @conditions[k] = Condition.new(v)
      end
      
      freeze
    end
    
    def match(env)
      request = Rack::Request.new(env)
      conditions.all? { |k, v| v =~ request.send(k) } && @params
    end
    
  private
  
    
    
  end
end