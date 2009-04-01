require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a route that has specified parameters" do
    
    before(:each) do
      prepare do |r|
        r.map "/:one/:two", :to => FooApp, :with => { :one => "hello", :two => "world" }, :name => :something
      end
    end
    
    it "uses the passed values when generating the route" do
      @app.url(:something, :one => "goodbye", :two => "moon").should == "/goodbye/moon"
    end
    
    it "uses the default parameters when none are passed" do
      @app.url(:something).should == "/hello/world"
    end
    
    it "allows mixing and matching between passed parameters and defaults" do
      @app.url(:something, :one => "goodbye").should == "/goodbye/world"
      @app.url(:something, :two => "moon").should == "/hello/moon"
    end
    
  end
  
end