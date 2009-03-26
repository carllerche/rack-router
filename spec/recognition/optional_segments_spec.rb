require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests," do
  
  describe "a route with optional segments", :shared => true do
    
    it "should match when the required segment matches" do
      route_for("/hello").should have_route(FooApp, :first => 'hello', :second => nil, :third => nil)
    end
    
    it "should match when the required and optional segment(s) match" do
      route_for("/hello/world/sweet").should have_route(FooApp, :first => "hello", :second => "world", :third => "sweet")
    end
    
  end
  
  describe "a single optional segment" do
    before(:each) do
      prepare do |r|
        r.map "/:first(/:second/:third)", :to => FooApp
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "should not match the route if the optional segment is only partially present" do
      route_for("/hello/world").should be_missing
    end
    
    it "should not match the optional segment if the optional segment is present but doesn't match a named segment condition" do
      prepare do |r|
        r.map "/:first(/:second)", :conditions => { :second => /\d+/ }
      end
      
      route_for("/hello/world").should be_missing
    end
    
    it "should not match if the optional segment is present but not the required segment" do
      prepare do |r|
        r.map "/:first(/:second)", :conditions => { :first => /^[a-z]+$/, :second => /^\d+$/ }
      end
      
      route_for("/123").should be_missing
    end
  end
  
  describe "multiple optional segments" do
    before(:each) do
      prepare do |r|
        r.map "/:first(/:second)(/:third)", :to => FooApp
      end
    end
    
    it_should_behave_like "a route with optional segments"
    
    it "should match when one optional segment matches" do
      route_for("/hello/sweet").should have_route(FooApp, :first => "hello", :second => "sweet", :third => nil)
    end
    
    it "should be able to distinguish the optional segments when there are conditions on them" do
      prepare do |r|
        r.map "/:first(/:second)(/:third)", :to => FooApp, :conditions => { :second => /\d+/ }
      end
      
      route_for("/hello/world").should have_route(FooApp, :first => "hello", :second => nil, :third => "world")
      route_for("/hello/123").should have_route(FooApp, :first => "hello", :second => "123", :third => nil)
    end
    
    it "should not match any of the optional segments if the segments can't be matched" do
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
    
    it "should match when the first optional segment matches" do
      route_for("/hello/world").should have_route(FooApp, :first => "hello", :second => "world", :third => nil)
    end
    
    it "should not match the nested optional group unless the containing optional group matches" do
      prepare do |r|
        r.map "/:first(/:second(/:third))", :to => FooApp, :conditions => { :second => /\d+/ }
      end
      
      route_for("/hello/world").should be_missing
    end
  end
  
end