require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests," do
  
  describe "a route with path variable" do
    
    it "should create keys for each named variable" do
      prepare do |r|
        r.map "/:foo/:bar", :to => VariableApp
      end
      
      route_for("/one/two").should have_route(VariableApp, :foo => "one", :bar => "two")
    end
    
    it "should be able to match :controller, :action, and :id from the route" do
      prepare do |r|
        r.map "/:controller/:action/:id", :get, :to => VariableApp
      end
      
      route_for("/foo/bar/baz").should have_route(VariableApp, :controller => "foo", :action => "bar", :id => "baz")
    end
    
    it "should be able to overwrite matched named variables in the params" do
      prepare do |r|
        r.map "/:foo/:bar", :to => VariableApp, :with => { :foo => "foo", :bar => "bar" }
      end
      
      route_for("/one/two").should have_route(VariableApp, :foo => "foo", :bar => "bar")
    end
    
    it "should be able to block named variables from being present in the params" do
      prepare do |r|
        r.map "/:foo/:bar", :to => VariableApp, :with => { :foo => nil, :bar => nil }
      end
      
      route_for("/one/two").should have_route(VariableApp, :foo => nil, :bar => nil)
    end
    
    it "should match single character names" do
      prepare do |r|
        r.map "/:x/:y", :to => VariableApp
      end
      
      route_for("/40/20").should have_route(VariableApp, :x => "40", :y => "20")
    end
    
    it "should not swallow trailing underscores in the segment name" do
      prepare do |r|
        r.map "/:foo_", :to => VariableApp
      end
      
      route_for("/buh_").should have_route(VariableApp, :foo => "buh")
      route_for("/buh").should  be_missing
    end
  end

  describe "a route with path variable conditions" do
    
    it "should match only if the condition is satisfied" do
      prepare do |r|
        r.map "/foo/:bar", :to => FooApp, :conditions => { :bar => /\d+/ }
      end
      
      route_for("/foo/123").should have_route(FooApp, :bar => "123")
      route_for("/foo/abc").should be_missing
    end
    
    it "should match only if all conditions are satisfied" do
      prepare do |r|
        r.map "/:foo/:bar", :to => FooApp, :conditions => { :foo => /abc/, :bar => /123/ }
      end
      
      route_for("/abc/123").should   have_route(FooApp, :foo => "abc",  :bar => "123")
      route_for("/abcd/123").should  be_missing
      route_for("/abc/1234").should  be_missing
      route_for("/abcd/1234").should be_missing
      route_for("/ab/123").should    be_missing
      route_for("/abc/12").should    be_missing
      route_for("/ab/12").should     be_missing
    end
    
    it "should allow creating conditions that span default segment dividers" do
      prepare do |r|
        r.map "/:lol", :to => FooApp, :conditions => { :lol => %r[[a-z]+/[a-z]+] }
      end
      
      route_for("/somewhere").should be_missing
      route_for("/somewhere/somehow").should have_route(FooApp, :lol => "somewhere/somehow")
    end
    
    it "should allow creating conditions that match everything" do
      prepare do |r|
        r.map "/:glob", :to => FooApp, :conditions => { :glob => /.*/ }
      end
      
      %w(somewhere somewhere/somehow 123/456/789 i;just/dont-understand).each do |path|
        route_for("/#{path}").should have_route(FooApp, :glob => path)
      end
    end
    
    it "should allow greedy matches to precede segments" do
      prepare do |r|
        r.map "/foo/:bar/something/:else", :to => FooApp, :conditions => { :bar => /.*/ }
      end
      
      %w(somewhere somewhere/somehow 123/456/789 i;just/dont-understand).each do |path|
        route_for("/foo/#{path}/something/wonderful").should have_route(FooApp, :bar => path, :else => "wonderful")
      end
    end
    
    it "should allow creating conditions that proceed a glob" do
      prepare do |r|
        r.map "/:foo/bar/:glob", :to => FooApp, :conditions => { :glob => /.*/ }
      end
      
      %w(somewhere somewhere/somehow 123/456/789 i;just/dont-understand).each do |path|
        route_for("/superblog/bar/#{path}").should have_route(FooApp, :foo => "superblog", :glob => path)
        route_for("/notablog/foo/#{path}").should be_missing
      end
    end
    
    it "should match only if all mixed conditions are satisfied" do
      prepare do |r|
        r.map "/:blog/post/:id", :to => FooApp, :conditions => { :blog => %r{[a-zA-Z]+}, :id => %r{[0-9]+} }
      end
      
      route_for("/superblog/post/123").should  have_route(FooApp, :blog => "superblog",  :id => "123")
      route_for("/superblawg/post/321").should have_route(FooApp, :blog => "superblawg", :id => "321")
      route_for("/superblog/post/asdf").should be_missing
      route_for("/superblog1/post/123").should be_missing
      route_for("/ab/12").should               be_missing
    end
    
  end
  
end