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
    
    it "does not add the optional segment when the optional segment is just a string" do
      prepare do |r|
        r.map "/:greets(/world)", :to => FooApp, :name => :optional
      end

      pending do
        @app.url(:optional, :greets => "goodbye").should == "/goodbye"
      end
    end

    it "only generates the route's required segment if it contains no variables" do
      prepare do |r|
        r.map "/hello(/:optional)", :to => FooApp, :name => :optional
      end

      @app.url(:optional).should == "/hello"
    end

    it "only generates the required segment of the route if the optional parameter is not provided" do
      @app.url(:optional, :foo => "hello").should == "/hello"
    end

    it "only generates the required segment of the route and add all extra parameters to the query string if the optional parameter is not provided" do
      @app.url(:optional, :foo => "hello", :extra => "world").should == "/hello?extra=world"
    end

    it "also generates the optional segment of the route if the parameter is provied" do
      @app.url(:optional, :foo => "hello", :bar => "world").should == "/hello/world"
    end

    it "generates the full optional segment of the route when there are multiple variables in the optional segment" do
      prepare do |r|
        r.map "/hello(/:foo/:bar)", :to => FooApp, :name => :long_optional
      end

      @app.url(:long_optional, :foo => "world", :bar => "hello").should == "/hello/world/hello"
    end

    it "does not generate the optional segment of the route if all the parameters of that optional segment are not provided" do
      prepare do |r|
        r.map "/hello(/:foo/:bar)", :to => FooApp, :name => :long_optional
      end

      @app.url(:long_optional, :foo => "world").should == "/hello?foo=world"
    end

    it "raises an error if the required parameters are not provided" do
      lambda { @app.url(:optional) }.should raise_error(ArgumentError)
    end

    it "raises an error if the required parameters are not provided even if optional parameters are" do
      lambda { @app.url(:optional, :bar => "hello") }.should raise_error(ArgumentError)
    end
    
  end
  
end