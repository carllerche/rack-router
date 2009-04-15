$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
require "spec"
require "rack/router"
require "ruby-debug" rescue nil # Temporary to make my life easier

module Spec
  module Helpers
    def prepare(options = {}, &block)
      @app = router(options, &block)
    end
    
    def router(options = {}, &block)
      Rack::Router.new(nil, options, &block)
    end
    
    def env_for(path, options = {})
      env = {}
      env["REQUEST_METHOD"]  = (options.delete(:method) || "GET").to_s.upcase
      env["REQUEST_URI"]     = ((options[:script_name] || "/") + path).squeeze("/")
      env["PATH_INFO"]       = path.squeeze("/").sub(%r'/$', '')
      env["SCRIPT_NAME"]     = options.delete(:script_name) || "/"
      env["HTTP_HOST"]       = options.delete(:host) || "example.org"
      env["rack.url_scheme"] = options[:scheme] if options[:scheme]
      env
    end
    
    def route_for(path, options = {})
      @app.call env_for(path, options)
    end
  end
  
  module Matchers
    
    class HaveRoute
      def initialize(app, expected, exact)
        @app, @expected, @exact = app, expected, exact
      end
      
      def matches?(target)
        @target = target
        
        if @target[0] == 200
          @resp  = Marshal.load(@target[2])
          params = @resp['rack_router.params']
          @app.to_s == @resp['app'] && @expected == params # && (!@exact || @expected.keys.length == @resp)
        end
      end
      
      def failure_message
        if @resp
          # "Route matched, but returned: #{@resp['app']} with #{@resp['routing_args'].inspect}"
          "Route matched, but returned: #{@resp.inspect}"
        else
          "Route did not match anything"
        end
      end
    end
    
    def have_route(app, expected = {})
      HaveRoute.new(app, expected, false)
    end
    
    def have_exact_route(app, expected = {})
      HaveRoute.new(app, expected, true)
    end
    
    def have_env(env)
      simple_matcher "the request to have #{env.inspect}" do |given, m|
        given_env = Marshal.load(given[2]) rescue nil
        
        m.failure_message = given[0] == 200 ?
          "expected the request to contain #{env.inspect}, but it was #{given_env.inspect}" :
          "the route could not be matched"
          
        given[0] == 200 && env.all? { |k, v| given_env[k] == v }
      end
    end
    
    def be_missing
      simple_matcher("a not found request") do |given, m|
        env = Marshal.load(given[2]) rescue nil
        
        m.failure_message = "expected the request to not match, but it did with: #{env.inspect}"
        given[0] == 404
      end
    end
  end
end

class FailApp
  def self.call(env)
    [ 400, { "Content-Type" => 'text/html' }, "418 I'm a teapot" ]
  end
end

Object.instance_eval do
  def const_missing(name)
    if name.to_s =~ /App$/
      Object.instance_eval %{
        class ::#{name}
          def self.call(env)
            env.delete("rack_router.route")
            [ 200, { "Content-Type" => 'text/yaml' }, Marshal.dump(env.merge("app" => "#{name}")) ]
          end
        end
        ::#{name}
      }
    else
      super
    end
  end
end

Spec::Runner.configure do |config|
  config.include(Spec::Helpers)
  config.include(Spec::Matchers)
end