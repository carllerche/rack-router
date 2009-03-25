require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests," do
  
  describe "a route with variables in the path" do
    
    it "should create keys for each named variable" do
      prepare do |r|
        r.map "/:foo/:bar", :get, :to => VariableApp
      end
      
      route_for("/one/two").should have_route(VariableApp, :foo => "one", :bar => "two")
    end
    
    it "should be able to match :controller, :action, and :id from the route" do
      prepare do |r|
        r.map "/:controller/:action/:id", :to => VariableApp
      end
      
      route_for("/foo/bar/baz").should have_route(VariableApp, :controller => "foo", :action => "bar", :id => "baz")
    end
    
    it "should be able to set :controller with #to" do
      pending "Not relevant?"
      Merb::Router.prepare do
        match("/:action").to(:controller => "users")
      end
      
      route_for("/show").should have_route(:controller => "users", :action => "show")
    end
    
    it "should be able to combine multiple named variables into a param" do
      pending "Not relevant?"
      Merb::Router.prepare do
        match("/:foo/:bar").to(:controller => ":foo/:bar")
      end
      
      route_for("/one/two").should have_route(:controller => "one/two", :foo => "one", :bar => "two")
    end
    
    it "should be able to overwrite matched named variables in the params" do
      prepare do |r|
        r.map "/:foo/:bar", :to => VariableApp, :with => { :foo => "foo", :bar => "bar" }
      end
      
      route_for("/one/two").should have_route(VariableApp, :foo => "foo", :bar => "bar")
    end
    
    it "should be able to block named variables from being present in the params" do
      prepare do |r|
        r.map "/:foo/:bar", :to => VariableApp, :with => { :foo => nil, :bar => nil }
      end
      
      route_for("/one/two").should have_route(VariableApp, :foo => nil, :bar => nil)
    end
    
    it "should match single character names" do
      prepare do |r|
        r.map "/:x/:y", :to => VariableApp
      end
      
      route_for("/40/20").should have_route(VariableApp, :x => "40", :y => "20")
    end
    
    it "should not swallow trailing underscores in the segment name" do
      prepare do |r|
        r.map "/:foo_", :to => VariableApp
      end
      
      route_for("/buh_").should have_route(VariableApp, :foo => "buh")
      route_for("/buh").should  be_missing
    end
  end
end