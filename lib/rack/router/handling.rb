class Rack::Router
  module Handling
    
    def handle(request, env)
      for route in @routes
        response = route.handle(request, env)
        return response if response && handled?(response)
      end
      
      NOT_FOUND_RESPONSE
    end
    
    # def compile
    #   (class << self ; self ; end).class_eval <<-EVAL, __FILE__, __LINE__+1
    #     def handle(request, env)
    #       #{compiled_statement}
    #       NOT_FOUND_RESPONSE
    #     end
    #   EVAL
    # end
    
  private
  
    def handled?(response)
      response[1][STATUS_HEADER] != NOT_FOUND
    end
    
    # def compiled_statement
    #   keys, body = [], ""
    #   
    #   @routes.each_with_index do |route, i|
    #     keys.concat route.request_conditions.keys
    #     
    #     body << route.compiled_statement(i) do
    #       <<-STATEMENT
    #         resp = route.app.call(env)
    #         return resp if resp && handled?(resp)
    #       STATEMENT
    #     end
    #   end
    #   
    #   keys.uniq!
    #   head = keys.map! { |k| "c_#{k} = request.#{k}" }.join(';')
    #   
    #   path_info = "o_path_info, o_script_name = env['PATH_INFO'], env['SCRIPT_NAME']"
    # 
    #   "#{head}\n#{path_info}\n#{body}"
    # end
  end
end