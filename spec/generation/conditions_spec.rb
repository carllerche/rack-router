require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a route with one condition" do
    
    it "generates when the string condition is met" do
      prepare do |r|
        r.map "/:account", :to => FooApp, :conditions => { :account => "walruses" }, :name => :condition
      end
    
      @app.url(:condition, :account => "walruses").should == "/walruses"
    end
    
    it "generates when the regexp condition that is met" do
      prepare do |r|
        r.map "/:account", :to => FooApp, :conditions => { :account => /[a-z]+/ }, :name => :condition
      end
    
      @app.url(:condition, :account => "walruses").should == "/walruses"
    end
    
    it "does not generate if the String condition is not met" do
      prepare do |r|
        r.map "/:account", :to => FooApp, :conditions => { :account => "walruses" }, :name => :condition
      end
    
      lambda { @app.url(:condition, :account => "pecans") }.should raise_error(ArgumentError)
    end
    
    it "does not generate if the Regexp condition is not met" do
      prepare do |r|
        r.map "/:account", :to => FooApp, :conditions => { :account => /[a-z]+/ }, :name => :condition
      end
      
      lambda { @app.url(:condition, :account => "29") }.should raise_error(ArgumentError)
    end
    
    it "works with numbers" do
      prepare do |r|
        r.map "/hello/:id", :to => FooApp, :conditions => { :id => /^\d+$/ }, :name => :number
      end
      
      @app.url(:number, :id => 10).should == "/hello/10"
      lambda { @app.url(:number, :id => true) }.should raise_error(ArgumentError)
    end
    
    it "implicitly uses regexp anchors around the condition" do
      prepare do |r|
        r.map "/:account", :to => FooApp, :conditions => { :account => /[a-z]+/ }, :name => :anchored
      end
      
      @app.url(:anchored, :account => "abc").should == "/abc"
      lambda { @app.url(:anchored, :account => "123abc") }.should raise_error(ArgumentError)
      lambda { @app.url(:anchored, :account => "abc123") }.should raise_error(ArgumentError)
    end
    
    it "works with Regexp conditions that contain capturing parentheses" do
      prepare do |r|
        r.map "/:domain", :to => FooApp, :conditions => { :domain => /[a-z]+\.(com|net)/ }, :name => :condition
      end
      
      @app.url(:condition, :domain => "foobar.com").should == "/foobar.com"
      lambda { @app.url(:condition, :domain => "foobar.org") }.should raise_error(ArgumentError)
    end
    
    it "works with Regexp conditions that contain non-capturing parentheses" do
      prepare do |r|
        r.map "/:domain", :to => FooApp, :conditions => { :domain => /[a-z]+\.(?:com|net)/ }, :name => :condition
      end
    
      @app.url(:condition, :domain => "foobar.com").should == "/foobar.com"
      lambda { @app.url(:condition, :domain => "foobar.org") }.should raise_error(ArgumentError)
    end
    
    it "should not take into consideration conditions on request methods" do
      prepare do |r|
        r.map "/one/two", :to => FooApp, :conditions => { :method => :post }, :name => :simple
      end
      
      @app.url(:simple).should == "/one/two"
    end
    
  end
  
  describe "a route with multiple conditions" do
    
    before(:each) do
      prepare do |r|
        r.map "/:one/:two", :to => FooApp, :conditions => { :one => "hello", :two => %r[^(world|moon)$] }, :name => :condition
      end
    end

    it "generates if all the conditions are met" do
      @app.url(:condition, :one => "hello", :two => "moon").should == "/hello/moon"
    end

    it "does not generate if any of the conditions fail" do
      lambda { @app.url(:condition, :one => "hello") }.should raise_error(ArgumentError)
      lambda { @app.url(:condition, :two => "world") }.should raise_error(ArgumentError)
    end

    it "appends any extra elements to the query string" do
      @app.url(:condition, :one => "hello", :two => "world", :three => "moon").should == "/hello/world?three=moon"
    end
    
  end
  
end