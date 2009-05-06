require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a route with a path and a host condition" do
    
    it "generates the full URL" do
      prepare do |r|
        r.map "/hello", :to => FooApp, :conditions => { :host => "awesome.com" }, :name => :hello
      end
    
      @app.url(:hello).should == "http://awesome.com/hello"
    end
    
    it "replaces variables in the host with the passed params" do
      prepare do |r|
        r.map "/hello", :to => FooApp, :conditions => { :host => ":account.awesome.com" }, :name => :hello
      end
      
      @app.url(:hello, :account => "carl").should == "http://carl.awesome.com/hello"
    end
    
  end
  
end