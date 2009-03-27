require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests" do
  
  it "handles embedding child routers" do
    pending
    prepare do |r|
      r.map "/hello", :to => Rack::Router.new { |c|
        c.map "/world", :to => FooApp
      }
    end
    
    route_for("/hello/world").should have_route(FooApp)
  end
  
end