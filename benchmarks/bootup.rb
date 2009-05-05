$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require "rubygems"
require "rack"
require "rack/router"
require "rbench"

SuccessApp = lambda { |env| }

RBench.run(100) do
  column :times
  column :one, :title => "rack-router bootup time"
  
  report "Awesome" do
    one do
      Rack::Router.new(nil) do |r|
        ("aa".."bm").each do |first|
          ("aa".."bm").each do |second|
            r.map "/#{first}/#{second}", :to => SuccessApp
          end
        end
      end
    end
  end
end