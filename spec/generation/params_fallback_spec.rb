require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a simple route" do
    
    it "uses the fallback params to populate required parameters that were not specified" do
      prepare do |r|
        r.map "/:one/:two", :to => FooApp, :name => :simple
      end
      
      @app.url(:simple, {:one => "foo"}, :two => "bar").should == "/foo/bar"
    end
    
    it "automatically checks fallback params for required segments even if no params from that segment are specified" do
      prepare do |r|
        r.map "/:one", :to => FooApp, :name => :simple
      end
      
      @app.url(:simple, {}, :one => "foo").should == "/foo"
    end
    
    it "does not append any fallback parameters to the query string" do
      prepare do |r|
        r.map "/hello", :to => FooApp, :name => :simple
      end
      
      @app.url(:simple, {}, {:foo => "bar"}).should == "/hello"
    end
    
    it "does not use fallback parameters for optional segments if no capture from that segment was explicitly specified" do
      prepare do |r|
        r.map "/hello(/:one/:two/:three)",     :to => FooApp, :name => :sequential
        r.map "/hello(/:one(/:two(/:three)))", :to => FooApp, :name => :nested
      end
      
      fallback = { :one => "uno", :two => "dos", :three => "tres" }
      @app.url(:sequential, {}, fallback).should == "/hello"
      @app.url(:nested,     {}, fallback).should == "/hello"
    end
    
    it "generates the optional segments if an element from it is specified" do
      prepare do |r|
        r.map "/hello(/:one/:two/:three)",     :to => FooApp, :name => :sequential
        r.map "/hello(/:one(/:two(/:three)))", :to => FooApp, :name => :nested
      end
      
      fallback = { :one => "uno", :two => "dos", :three => "tres" }
      
      @app.url(:sequential, {:one   => "hi"}, fallback).should == "/hello/hi/dos/tres"
      @app.url(:sequential, {:two   => "hi"}, fallback).should == "/hello/uno/hi/tres"
      @app.url(:sequential, {:three => "hi"}, fallback).should == "/hello/uno/dos/hi"
      @app.url(:nested,     {:one   => "hi"}, fallback).should == "/hello/hi"
      @app.url(:nested,     {:two   => "hi"}, fallback).should == "/hello/uno/hi"
      @app.url(:nested,     {:three => "hi"}, fallback).should == "/hello/uno/dos/hi"
    end
    
  end
  
  describe "a route with segment conditions" do
    
    before(:each) do
      prepare do |r|
        r.map "/:one(/:two/:three(/:four))", :to => FooApp, :name => :numbers, :conditions => { :one => /^\d+$/, :two => /^\d+$/, :three => /^\d+$/, :four => /^\d+$/ }
      end
    end
    
    it "uses the fallback params if using them will satisfy all the routes' conditions" do
      @app.url(:numbers, { :three => '3' }, :one => '1', :two => '2').should == "/1/2/3"
    end
    
    it "does not generate paths that don't match the conditions and append passed params that didn't match to the query string" do
      @app.url(:numbers, {:three => '3'}, :one => '1', :two => 'two').should == '/1?three=3'
      @app.url(:numbers, {:four => 'four'}, :one => '1', :two => '2', :three => '3').should == "/1?four=four"
    end
    
  end
  
end