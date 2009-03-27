$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require "yaml"
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
          @resp = YAML.load(@target[2])
          @app.to_s == @resp['app'] && @expected == @resp['rack.routing_args']
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
    
    def be_missing
      simple_matcher("a not found request") do |given|
        given[0].should == 404
      end
    end
  end
end

Object.instance_eval do
  def const_missing(name)
    if name.to_s =~ /App$/
      Object.instance_eval %{
        class ::#{name}
          def self.call(env)
            resp = {}
            resp['rack.routing_args'] = env['rack.routing_args']
            resp['app'] = '#{name}'
            
            [ 200, { "Content-Type" => 'text/yaml' }, YAML.dump(resp) ]
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