require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests," do

  describe "a route with a String path condition" do
  
    before(:each) do
      prepare do |r|
        r.map "/info", :get, :to => FooApp, :with => { :action => "info" }
      end
    end
  
    it "should match the path and return the paramters passed in" do
      route_for("/info").should have_route(FooApp, :action => "info")
    end
  
    it "should not match a different path" do
      route_for("/notinfo").should be_missing
    end
  
    it "should ignore trailing slashes" do
      prepare do |r|
        r.map "/info/", :get, :to => FooApp, :with => { :action => "info" }
      end
      
      route_for("/info").should have_route(FooApp, :action => "info")
    end
  
    it "should ignore repeated slashes" do
      prepare do |r|
        r.map "//info", :get, :to => FooApp, :with => { :action => "info" }
      end
      
      route_for("/info").should have_route(FooApp, :action => "info")
    end
    
    it "should map to the correct rack app" do
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
    
    it "should match any path with a post method" do
      route_for("/foo/create/12", :method => "post").should have_route(PostingApp, :action => "posting")
      route_for("", :method => "post").should               have_route(PostingApp, :action => "posting")
    end
    
    it "should not match any paths that don't have a post method" do
      route_for("/foo/create/12", :method => "get").should be_missing
      route_for("", :method => "get").should be_missing
    end
    
    it "should combine Array elements using OR" do
      prepare do |r|
        r.map nil, [:get, :post], :to => HelloApp, :with => { :action => "index" }
      end
      
      route_for('/anything', :method => "get").should    have_route(HelloApp, :action => "index")
      route_for('/anything', :method => "post").should   have_route(HelloApp, :action => "index")
      route_for('/anything', :method => "put").should    be_missing
      route_for('/anything', :method => "delete").should be_missing
    end
    
    it "should be able to handle Regexps inside of condition arrays" do
      prepare do |r|
        r.map nil, [/^g[aeiou]?t$/i, :post], :to => HelloApp
      end
      
      route_for('/anything', :method => "get").should    have_route(HelloApp)
      route_for('/anything', :method => "post").should   have_route(HelloApp)
      route_for('/anything', :method => "put").should    be_missing
      route_for('/anything', :method => "delete").should be_missing
    end
    
    it "should ignore nil values" do
      prepare do |r|
        r.map "/hello", :method => nil, :to => HelloApp
      end
      
      [:get, :post, :puts, :delete].each do |method|
        route_for("/hello", :method => method).should have_route(HelloApp)
      end
    end
  end
  
end