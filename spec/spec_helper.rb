$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

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
        @expected = expected
      end
      
      def matches?(target)
        @target = target
        false
      end
      
      def failure_message
        @target.inspect
      end
    end
    
    def have_route(app, expected)
      HaveRoute.new(app, expected)
    end
  end
end

EchoApp = lambda do |env|
  [ 200, { "Content-Type" => 'text/yaml' }, "Hello World!" ]
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