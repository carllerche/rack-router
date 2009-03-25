class Rack::Router
  class Route
    
    attr_reader   :app, :conditions, :params
    attr_accessor :name
    
    def initialize(app, conditions, params)
      @app, @conditions, @params = app, conditions, params
    end
    
    def compile
      @conditions.each do |k, pattern|
        @conditions[k] = Condition.new(pattern)
      end
      
      freeze
    end
    
    def match(env)
      request  = Rack::Request.new(env)
      captures = {}
      
      return unless conditions.all? do |method_name, condition|
        capts = condition.match(request.send(method_name)) and captures.merge!(capts)
      end
      
      captures.merge! @params
    end
    
  private
  
    
    
  end
end