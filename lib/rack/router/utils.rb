class Rack::Router
  module Utils
    
    # Normalizes the path by replacing any repeated slashes with a single
    # slash and removing the trailing slash. If a single slash is passed
    # in, an empty string will be returned.
    #
    # ==== Parameters
    # path<String>:: The URI path to normalize
    #
    # ==== Returns
    # String:: The normalized path
    #
    # :api: public
    def normalize(path)
      "/#{path}".squeeze("/").sub(%r'/+$', '')
    end
    
    module_function :normalize 
    
  end
end