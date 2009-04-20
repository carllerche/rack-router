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
    
    # Returns the number of captures for a given regular expression
    def regexp_arity(regexp)
      return 0 unless regexp.is_a?(Regexp)
      regexp.source.scan(/(?!\\)[(](?!\?[#=:!>-imx])/).length
    end
    
    module_function :regexp_arity
    
  end
end