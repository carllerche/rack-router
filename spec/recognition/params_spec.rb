require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests" do
  
  describe "a route a simple param builder" do
    
    it "should provide the params specified in 'to' statements" do
      prepare do |r|
        r.map "/hello", :to => FooApp, :with => { :foo => "bar" }
      end
      
      route_for("/hello").should have_route(FooApp, :foo => "bar")
    end
    
    it "should be able to handle Numeric params" do
      prepare do |r|
        r.map "/hello", :to => FooApp, :with => { :integer => 10, :float => 5.5 }
      end
      
      route_for("/hello").should have_route(FooApp, :integer => 10, :float => 5.5)
    end
    
    it "should be able to handle Boolean params" do
      prepare do |r|
        r.map "/hello", :to => FooApp, :with => { :true => true, :false => false }
      end
      
      route_for("/hello").should have_route(FooApp, :true => true, :false => false)
    end

    it "should be able to extract named segments as params" do
      prepare do |r|
        r.map "/:foo", :to => FooApp
      end

      route_for('/bar').should have_route(FooApp, :foo => "bar")
    end

    it "should be able to extract multiple named segments as params" do
      prepare do |r|
        r.map "/:foo/:faz", :to => FooApp
      end

      route_for("/bar/baz").should have_route(FooApp, :foo => "bar", :faz => "baz")
    end
    
  end
  
end