$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require "yaml"
require "rubygems"
require "spec"
require "rack/router"

module Spec
  module Helpers
    def prepare(options = {}, &block)
      @app = Rack::Router.new(nil, options, &block)
    end
    
    def env_for(path, options = {})
      {
        "REQUEST_METHOD" => options.delete(:method) || "GET",
        "PATH_INFO"      => path
      }
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
          @routing_args = YAML.load(@target[2])['rack.routing_args']
          @expected == @routing_args
        end
      end
      
      def failure_message
        if @routing_args
          "Route matched, but returned: #{@routing_args.inspect}"
        else
          "Route did not match anything"
        end
      end
    end
    
    def have_route(app, expected)
      HaveRoute.new(app, expected)
    end
  end
end

EchoApp = lambda do |env|
  [ 200, { "Content-Type" => 'text/yaml' }, YAML.dump(env) ]
end

Object.instance_eval do
  def const_missing(name)
    if name.to_s =~ /App$/
      EchoApp
    else
      super
    end
  end
end

Spec::Runner.configure do |config|
  config.include(Spec::Helpers)
  config.include(Spec::Matchers)
end