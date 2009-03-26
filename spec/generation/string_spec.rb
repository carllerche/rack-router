require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a plain named route with no variables" do
    
    before(:each) do
      prepare do |r|
        r.map "/hello/world", :to => FooApp, :name => :simple
      end
    end
    
    it "generates with no parameters" do
      @app.url(:simple).should == "/hello/world"
    end

    it "appends any parameters to the query string" do
      pending do
        @app.url(:simple, :foo => "bar").should == "/hello/world?foo=bar"
      end
    end
    
  end
  
  describe "a named route with a variable and no conditions" do
    
    before(:each) do
      prepare do |r|
        r.map "/:account/welcome", :to => FooApp, :name => :welcome
      end
    end

    it "generates a URL with a paramter passed for the variable" do
      @app.url(:welcome, :account => "walruses").should == "/walruses/welcome"
    end

    it "appends any extra parameters to the query string" do
      pending do
        @app.url(:welcome, :account => "seagulls", :like_walruses => "true").should == "/seagulls/welcome?like_walruses=true"
      end
    end

    it "raises an error if no parameters are passed" do
      lambda { @app.url(:welcome) }.should raise_error(ArgumentError)
    end
    
    it "raises an error if a nil parameter is passed" do
      lambda { @app.url(:welcome, :account => nil) }.should raise_error(ArgumentError)
    end
    
    it "raises an error if a blank parameter is passed" do
      lambda { @app.url(:welcome, :account => "") }.should raise_error(ArgumentError)
    end

    it "raises an error if parameters are passed without :account" do
      lambda { @app.url(:welcome, :foo => "bar") }.should raise_error(ArgumentError)
    end
    
  end
  
end