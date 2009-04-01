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
  
  describe "a route that has an optional segment with one capture and has specified defaults for it" do
    
    before(:each) do
      prepare do |r|
        r.map "/hello(/:planet)", :to => FooApp, :with => { :planet => "world" }, :name => :greetings
      end
    end
    
    it "generates, but omits the optional segment if no parameters are passed" do
      @app.url(:greetings).should == "/hello"
    end
    
    it "generates the optional segment when specifying it explicitly" do
      @app.url(:greetings, :planet => "mars").should == "/hello/mars"
    end
    
  end
  
  describe "a route that has an optional segment with two captures and has specified defaults for one of them" do
    
    before(:each) do
      prepare do |r|
        r.map "/hello(/:first/and/:second)", :to => FooApp, :with => { :first => "world" }, :name => :greetings
      end
    end
    
    it "generates, but omits the optional segment if no parameters are passed" do
      @app.url(:greetings).should == "/hello"
    end
    
    it "generates with the optional segment if both parameters are passed" do
      @app.url(:greetings, :first => "pluto", :second => "jupiter").should == "/hello/pluto/and/jupiter"
    end
    
    it "generates with the optional segment if the parameter with no default is specified" do
      @app.url(:greetings, :second => "jupiter").should == "/hello/world/and/jupiter"
    end
    
    it "generates and adds the parameter to the query string if an optional segment is not fully satisfied" do
      @app.url(:greetings, :first => "jupiter").should == "/hello?first=jupiter"
    end
    
  end
  
  describe "a route that has nested optional segments with a captures each and has specified defaults for both of them" do
    
    before(:each) do
      prepare do |r|
        r.map "/hello(/:first(/and/:second))", :to => FooApp, :with => { :first => "world", :second => "moon" }, :name => :greetings
      end
    end
    
    it "generates but omits the optional segments if no parameters are passed" do
      @app.url(:greetings).should == "/hello"
    end
    
    it "generates both optional segments if parameters are passed for both of them" do
      @app.url(:greetings, :first => "pluto", :second => "uranus").should == "/hello/pluto/and/uranus"
    end
    
    it "generates the first optional segment if a parameter is passed for it" do
      @app.url(:greetings, :first => "pluto").should == "/hello/pluto"
    end
    
    it "generates both optional segments if a parameter is passed for the second one" do
      @app.url(:greetings, :second => "mars").should == "/hello/world/and/mars"
    end
    
  end
  
  describe "a route that has nested optional segments with a captures each and has specified defaults for the last one" do
    
    before(:each) do
      prepare do |r|
        r.map "/hello(/:first(/and/:second))", :to => FooApp, :with => { :second => "moon" }, :name => :greetings
      end
    end
    
    it "generates but omits the optional segments if no parameters are passed" do
      @app.url(:greetings).should == "/hello"
    end
    
    it "generates both optional segments if parameters are passed for both of them" do
      @app.url(:greetings, :first => "pluto", :second => "uranus").should == "/hello/pluto/and/uranus"
    end
    
    it "generates the first optional segment if a parameter is passed for it" do
      @app.url(:greetings, :first => "pluto").should == "/hello/pluto"
    end
    
    it "generates and adds the parameter to the query string if the parent optional segment is not satisfied" do
      @app.url(:greetings, :second => "mars").should == "/hello?second=mars"
    end
    
  end
  
end