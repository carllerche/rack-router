require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a named route with a single optional segment" do
    
    before(:each) do
      prepare do |r|
        r.map "/:foo(/:bar)", :to => FooApp, :name => :optional
      end
    end
    
    it "does not generate the optional segment when all segments are just strings" do
      prepare do |r|
        r.map "/hello(/world)", :to => FooApp, :name => :optional
      end

      pending do
        @app.url(:optional).should == "/hello"
      end
    end
    
  end
  
end