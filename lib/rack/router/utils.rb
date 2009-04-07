class Rack::Router
  module Utils
    
    def normalize(pattern)
      "/#{pattern}".squeeze("/").sub(%r'/+$', '')
    end
    
    module_function :normalize 
    
  end
end