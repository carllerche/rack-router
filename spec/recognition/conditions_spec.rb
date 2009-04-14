require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests" do

  describe "a route with a String path condition" do
  
    before(:each) do
      prepare do |r|
        r.map "/info", :get, :to => FooApp, :with => { :action => "info" }
      end
    end
  
    it "matches the path and return the paramters passed in" do
      route_for("/info").should have_route(FooApp, :action => "info")
    end
  
    it "does not match a different path" do
      route_for("/notinfo").should be_missing
    end
  
    it "ignores trailing slashes" do
      prepare do |r|
        r.map "/info/", :get, :to => FooApp, :with => { :action => "info" }
      end
      
      route_for("/info").should have_route(FooApp, :action => "info")
    end
  
    it "ignores repeated slashes" do
      prepare do |r|
        r.map "//info", :get, :to => FooApp, :with => { :action => "info" }
      end
      
      route_for("/info").should have_route(FooApp, :action => "info")
    end
    
    it "maps to the correct rack app" do
      prepare do |r|
        r.map "/first",  :get, :to => FirstApp
        r.map "/second", :get, :to => SecondApp
      end
      
      route_for("/second").should have_route(SecondApp)
    end
    
  end
  
  describe "a route with a Request method condition" do
    
    before(:each) do
      prepare do |r|
        r.map nil, :post, :to => PostingApp, :with => { :action => "posting" }
      end
    end
    
    it "matches any path with a post method" do
      route_for("/foo/create/12", :method => "post").should have_route(PostingApp, :action => "posting")
      route_for("", :method => "post").should               have_route(PostingApp, :action => "posting")
    end
    
    it "does not match any paths that don't have a post method" do
      route_for("/foo/create/12", :method => "get").should be_missing
      route_for("", :method => "get").should be_missing
    end
    
    it "can use a regular expression to specify OR" do
      prepare do |r|
        r.map nil, /get|post/i, :to => HelloApp, :with => { :action => "index" }
      end
      
      route_for('/anything', :method => "get").should    have_route(HelloApp, :action => "index")
      route_for('/anything', :method => "post").should   have_route(HelloApp, :action => "index")
      route_for('/anything', :method => "put").should    be_missing
      route_for('/anything', :method => "delete").should be_missing
    end
    
    it "ignores nil values" do
      prepare do |r|
        r.map "/hello", :method => nil, :to => HelloApp
      end
      
      [:get, :post, :puts, :delete].each do |method|
        route_for("/hello", :method => method).should have_route(HelloApp)
      end
    end
    
    describe "a route with an arbitrary Request method condition and a path condition" do

      before(:each) do
        prepare do |r|
          r.map "/foo", :to => ProtocolApp, :conditions => { :scheme => "http" }, :with => { :action => "text" }
        end
      end

      it "matches the route if the path and the protocol match" do
        route_for("/foo", :scheme => "http").should have_route(ProtocolApp, :action => "text")
      end

      it "does not match if the route does not match" do
        route_for("/bar", :scheme => "http").should be_missing
      end

      it "does not match if the protocol does not match" do
        route_for("/foo", :scheme => "https").should be_missing
      end

      it "can use regular expressions" do
        prepare do |r|
          r.map "/hello", /get|post/i, :to => HelloApp
        end

        route_for("/hello",   :method => "get").should    have_route(HelloApp)
        route_for("/hello",   :method => "post").should   have_route(HelloApp)
        route_for("/hello",   :method => "put").should    be_missing
        route_for("/hello",   :method => "delete").should be_missing
        route_for("/goodbye", :method => "get").should    be_missing
        route_for("/goodbye", :method => "post").should   be_missing
        route_for("/goodbye", :method => "put").should    be_missing
        route_for("/goodbye", :method => "delete").should be_missing
      end
    end
  end

end
