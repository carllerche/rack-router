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

      @app.url(:optional).should == "/hello"
    end
    
    it "does not add the optional segment when the optional segment is just a string" do
      prepare do |r|
        r.map "/:greets(/world)", :to => FooApp, :name => :optional
      end

      @app.url(:optional, :greets => "goodbye").should == "/goodbye"
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
  
  describe "a named route with nested optional segments" do
    
    before(:each) do
      prepare do |r|
        r.map "/:controller(/:action(/:id))", :to => FooApp, :name => :nested
      end
    end

    it "generates the full route if all the necessary paramters are supplied" do
      @app.url(:nested, :controller => "users", :action => "show", :id => 5).should == "/users/show/5"
    end

    it "generates only the required segment if no optional paramters are supplied" do
      @app.url(:nested, :controller => "users").should == "/users"
    end

    it "generates the first optional level when deeper levels are not provided" do
      @app.url(:nested, :controller => "users", :action => "show").should == "/users/show"
    end

    it "adds deeper level of optional parameters to the query string if a middle level is not provided" do
      @app.url(:nested, :controller => "users", :id => 5).should == "/users?id=5"
    end

    it "raises an error if the required segment is not provided" do
      lambda { @app.url(:nested, :action => "show") }.should raise_error(ArgumentError)
      lambda { @app.url(:nested, :id => 5) }.should raise_error(ArgumentError)
      lambda { @app.url(:nested, :action => "show", :id => 5) }.should raise_error(ArgumentError)
    end

    it "adds extra parameters to the query string" do
      @app.url(:nested, :controller => "users", :foo => "bar").should == "/users?foo=bar"
      @app.url(:nested, :controller => "users", :action => "show", :foo => "bar").should == "/users/show?foo=bar"
      @app.url(:nested, :controller => "users", :action => "show", :id => "2", :foo => "bar").should == "/users/show/2?foo=bar"
    end
    
  end
  
  describe "a named route with multiple optional segments" do
    
    before(:each) do
      prepare do |r|
        r.map "/:controller(/:action)(.:format)", :to => FooApp, :name => :multi
      end
    end

    it "generates the full route if all the parameters are provided" do
      @app.url(:multi, :controller => "articles", :action => "recent", :format => "rss").should == "/articles/recent.rss"
    end

    it "generates the first optional segment without the second when the second segment is not specified" do
      @app.url(:multi, :controller => "articles", :action => "recent").should == "/articles/recent"
    end

    it "generates the second optional segment without the first when the first segment is not specified" do
      @app.url(:multi, :controller => "articles", :format => "xml").should == "/articles.xml"
    end
    
  end
  
  describe "a named route with multiple optional segments containing nested optional segments" do
    
    before(:each) do
      prepare do |r|
        r.map "/:controller(/:action(/:id))(.:format)", :to => FooApp, :name => :default
      end
    end

    it "generates the full route when all the parameters are provided" do
      @app.url(:default, :controller => "posts", :action => "show", :id => "5", :format => :js).should ==
        "/posts/show/5.js"
    end

    it "generates with just the required parameter" do
      @app.url(:default, :controller => "posts").should == "/posts"
    end

    it "generates the first optional segment without the second when the second segment is not specified" do
      @app.url(:default, :controller => "posts", :action => "show").should == "/posts/show"
      @app.url(:default, :controller => "posts", :action => "show", :id => "5").should == "/posts/show/5"
    end

    it "generates the second optional segment without the first when the first segment is not specified" do
      @app.url(:default, :controller => "posts", :format => "html").should == "/posts.html"
    end
    
  end
  
end