class Rack::Router
  module Handling
    
    def handle(request, env)
      for route in @routes
        response = route.handle(request, env)
        return response if response && handled?(response)
      end
      
      NOT_FOUND_RESPONSE
    end
    
  private
  
    def handled?(response)
      response[1][STATUS_HEADER] != NOT_FOUND
    end
    
  end
end