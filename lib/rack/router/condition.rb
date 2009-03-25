class Rack::Router
  class Condition
    
    def initialize(pattern, enable_captures = true)
      @pattern = pattern
    end
    
    def =~(other)
      @pattern == other
    end
    
  end
end