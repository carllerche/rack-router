$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
require "spec"
require "rack/router"

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
      env["PATH_INFO"]       = path
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
      def initialize(app, expected)
        @app, @expected = app, expected
      end
      
      def matches?(target)
        @target = target
        
        if @target[0] == 200
          @resp = Marshal.load(@target[2])
          @app.to_s == @resp['app'] && @expected == @resp['rack_router.params']
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
      HaveRoute.new(app, expected)
    end
    
    def have_env(env)
      simple_matcher "the request to have #{env.inspect}" do |given, m|
        if given[0] == 200
          given = Marshal.load(given[2])
          m.failure_message = "expected the request to contain #{env.inspect}, but it was: #{given.inspect}"
          env.all? { |k, v| given[k] == v }
        else
          m.failure_message = "The route could not be matched"
          false
        end
      end
    end
    
    def be_missing
      simple_matcher("a not found request") do |given|
        given[0].should == 404
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
            resp = {}
            resp['rack_router.params'] = env['rack_router.params']
            resp['SCRIPT_NAME'] = env['SCRIPT_NAME']
            resp['PATH_INFO'] = env['PATH_INFO']
            resp['app'] = '#{name}'
            
            [ 200, { "Content-Type" => 'text/yaml' }, Marshal.dump(resp) ]
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