require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests" do
  
  describe "a route with optional segments", :shared => true do
    
    it "matches when the required segment matches" do
      route_for("/hello").should have_route(FooApp, :first => 'hello')
    end
    
    it "matches when the required and optional segment(s) match" do
      route_for("/hello/world/sweet").should have_route(FooApp, :first => "hello", :second => "world", :third => "sweet")
    end
    
  end
  
  describe "a single optional segment" do
    before(:each) do
      prepare do |r|
        r.map "/:first(/:second/:third)", :to => FooApp, :anchor => true
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "does not match the route if the optional segment is only partially present" do
      route_for("/hello/world").should be_missing
    end
    
    it "matches the route if it is not anchored, but does not populate the optional parameters" do
      prepare do |r|
        r.map "/:first(/:second/:third)", :to => FooApp
      end
      
      route_for("/hello/world").should have_route(FooApp, :first => "hello")
      route_for("/hello/world").should have_env("PATH_INFO" => "/world")
    end
    
    it "does not match the optional segment if the optional segment is present but doesn't match a named segment condition" do
      prepare do |r|
        r.map "/:first(/:second)", :to => FooApp, :conditions => { :second => /\d+/ }, :anchor => true
      end
      
      route_for("/hello/world").should be_missing
    end
    
    it "matches the route if not optional but does not populate the optional segment since it does not satisfy the conditions" do
      prepare do |r|
        r.map "/:first(/:second)", :to => FooApp, :conditions => { :second => /\d+/ }
      end
      
      route_for("/hello/world").should have_route(FooApp, :first => "hello")
      route_for("/hello/world").should have_env("PATH_INFO" => "/world")
    end
    
    it "does not match if the optional segment is present but not the required segment" do
      prepare do |r|
        r.map "/:first(/:second)", :to => FooApp, :conditions => { :first => /^[a-z]+$/, :second => /^\d+$/ }
      end
      
      route_for("/123").should be_missing
    end
    
    it "uses the captured param if the optional segment matches" do
      prepare do |r|
        r.map "/:first(/:second)", :to => FooApp, :with => { :second => "omghi2u" }
      end
      
      route_for("/hello/world").should have_route(FooApp, :first => "hello", :second => "world")
    end
    
    it "populates the optional params with the defaults if the optional segment is not matched" do
      prepare do |r|
        r.map "/:first(/:second)", :to => FooApp, :with => { :second => "omghi2u" }
      end
      
      route_for("/hello").should have_route(FooApp, :first => "hello", :second => "omghi2u")
    end
  end
  
  describe "multiple optional segments" do
    before(:each) do
      prepare do |r|
        r.map "/:first(/:second)(/:third)", :to => FooApp
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "matches when one optional segment matches" do
      route_for("/hello/sweet").should have_route(FooApp, :first => "hello", :second => "sweet")
    end
    
    it "distinguishes the optional segments when there are conditions on them" do
      prepare do |r|
        r.map "/:first(/:second)(/:third)", :to => FooApp, :conditions => { :second => /\d+/ }
      end
      
      route_for("/hello/world").should have_route(FooApp, :first => "hello", :third => "world")
      route_for("/hello/123").should have_route(FooApp, :first => "hello", :second => "123")
    end
    
    it "does not match any of the optional segments if the segments can't be matched" do
      prepare do |r|
        r.map "(/:first/abc)(/:bar)", :to => FooApp
      end
      
      route_for("/abc/hello").should       be_missing
      route_for("/hello/world/abc").should be_missing
    end
  end
  
  describe "nested optional segments" do
    before(:each) do
      prepare do |r|
        r.map "/:first(/:second(/:third))", :to => FooApp
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "matches when the first optional segment matches" do
      route_for("/hello/world").should have_route(FooApp, :first => "hello", :second => "world")
    end
    
    it "does not match the nested optional group unless the containing optional group matches" do
      prepare do |r|
        r.map "/:first(/:second(/:third))", :to => FooApp, :conditions => { :second => /\d+/ }, :anchor => true
      end
      
      route_for("/hello/world").should be_missing
    end
    
    it "matches the route when not anchored but does not populate any optional segments if the middle one does not satisfy the conditions" do
      prepare do |r|
        r.map "/:first(/:second(/:third))", :to => FooApp, :conditions => { :second => /\d+/ }
      end
      
      route_for("/hello/world").should have_route(FooApp, :first => "hello")
      route_for("/hello/world").should have_env("PATH_INFO" => "/world")
    end
  end
  
end