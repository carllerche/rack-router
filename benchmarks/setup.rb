$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "rubygems"
require "rack"
require "rack/router"
# For comparison purposes
require "merb-core"
require "rbench"

def env_for(path, options = {})
  env = {}
  env["REQUEST_METHOD"]  = (options.delete(:method) || "GET").to_s.upcase
  env["REQUEST_URI"]     = ((options[:script_name] || "/") + path).squeeze("/")
  env["PATH_INFO"]       = path
  env["SCRIPT_NAME"]     = options.delete(:script_name) || "/"
  env["HTTP_HOST"]       = options.delete(:host) || "example.org"
  env["rack.url_scheme"] = options[:scheme] if options[:scheme]
  env
end

def prepare(options = {}, &block)
  Rack::Router.new(nil, options, &block)
end

class SuccessApp
  def self.call(env)
    [ 200, { "Content-Type" => "text/html" }, "Success" ]
  end
end

