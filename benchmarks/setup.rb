$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "rubygems"
require "rack"
require "rack/router"
require "rbench"
# For comparison purposes
require "merb-core"           # Merb
require "sinatra/base"        # Sinatra
require "action_controller"   # Rails

def env_for(path, options = {})
  env = Rack::MockRequest::DEFAULT_ENV.dup
  env["REQUEST_METHOD"]  = (options.delete(:method) || "GET").to_s.upcase
  env["REQUEST_URI"]     = ((options[:script_name] || "/") + path).squeeze("/")
  env["PATH_INFO"]       = path
  env["SCRIPT_NAME"]     = options.delete(:script_name) || "/"
  env["HTTP_HOST"]       = options.delete(:host) || "example.org"
  env["rack.url_scheme"] = options[:scheme] if options[:scheme]
  env
end

def build_requests(path, options = {})
  env = env_for(path, options = {})
  return env, Merb::Request.new(env), Sinatra::Request.new(env), env
end

# ==== rack-router ====
def prepare(options = {}, &block)
  Rack::Router.new(nil, options, &block)
end

class SuccessApp
  def self.call(env)
    [ 200, { "Content-Type" => "text/html" }, "Success" ]
  end
end

# ==== Sinatra ====
module Sinatra
  class Mocked < Base
    
    def call(request)
      dup.call!(request)
    end
    
    def call!(request)
      @env, @request = request.env, request
      catch(:halt) { route! }
    end
    
    def route!
      super
    end
  end
end

# ==== Ruby on Rails setup ====
class RailsGenerator ; end

def draw(&block)
  ActionController::Routing::Routes.draw(&block)
  RailsGenerator.send(:include, ActionController::UrlWriter)
  RailsGenerator.protected_instance_methods.each do |method|
    RailsGenerator.send(:public, method)
  end
  RailsGenerator.default_url_options = { :host => "example.org" }
  RailsGenerator.new
end

class SuccessController < ActionController::Base
  def self.call(env)
    [ 200, { "Content-Type" => "text/html" }, "Success" ]
  end
end