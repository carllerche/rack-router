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
       @app.url(:simple, :foo => "bar").should == "/hello/world?foo=bar"
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
      @app.url(:welcome, :account => "seagulls", :like_walruses => "true").should == "/seagulls/welcome?like_walruses=true"
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
  
  describe "a named route with multiple variables and no conditions" do
    
    before(:each) do
      prepare do |r|
        r.map "/:foo/:bar", :to => FooApp, :name => :foobar
      end
    end

    it "generates a URL with parameters passed for both variables" do
      @app.url(:foobar, :foo => "omg", :bar => "hi2u").should == "/omg/hi2u"
    end

    it "generates a URL with parameters passed for both variables that need escaping" do
      @app.url(:foobar, :foo => "om#g", :bar => "hi 2u").should == "/om%23g/hi%202u"
    end

    it "appends any extra parameters to the query string" do
      @app.url(:foobar, :foo => "omg", :bar => "hi2u", :fiz => "what", :biz => "bat").should =~ %r[\?(fiz=what&biz=bat|biz=bat&fiz=what)$]
    end
    
    it "does not append nil parameters to the query string" do
      @app.url(:foobar, :foo => "omg", :bar => "hi2u", :fiz => nil).should == "/omg/hi2u"
    end
    
    it "does append empty string parameters to the query string" do
      @app.url(:foobar, :foo => "omg", :bar => "hi2u", :fiz => "").should == "/omg/hi2u?fiz="
    end

    it "raises an error if the first variable is missing" do
      lambda { @app.url(:foobar, :bar => "hi2u") }.should raise_error(ArgumentError)
    end

    it "raises an error if the second variable is missing" do
      lambda { @app.url(:foobar, :foo => "omg") }.should raise_error(ArgumentError)
    end

    it "raises an error no variables are passed" do
      lambda { @app.url(:foobar) }.should raise_error(ArgumentError)
    end
    
  end
  
end