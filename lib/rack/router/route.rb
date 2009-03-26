class Rack::Router
  class Route
    
    attr_reader   :app, :request_conditions, :segment_conditions, :params
    attr_accessor :name
    
    def initialize(app, request_conditions, segment_conditions, params)
      @app                = app
      @request_conditions = request_conditions
      @segment_conditions = segment_conditions
      @params             = params
    end
    
    def compile
      @request_conditions.each do |k, pattern|
        @request_conditions[k] = Condition.new(pattern, segment_conditions)
      end
      
      freeze
    end
    
    def match(env)
      request  = Rack::Request.new(env)
      captures = {}
      
      return unless request_conditions.all? do |method_name, condition|
        next true unless request.respond_to?(method_name)
        capts = condition.match(request.send(method_name)) and captures.merge!(capts)
      end
      
      captures.merge! @params
    end
    
  end
end