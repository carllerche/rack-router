require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  before(:each) do
    pending
  end
  
  describe "a router with dependencies" do
    
    before(:each) do
      @dependency = Class.new(Rack::Router) do
        def initialize(*args)
          prepare do |r|
            r.map "/something", :to => FooApp, :name => :dependency
          end
        end
      end
    end
    
    it "provides access to the dependencies" do
      child = Rack::Router.new(:dependencies => { @dependency => :woot }) { |r| }
      
      prepare do |r|
        r.map "/foo", :to => @dependency.new
        r.map "/bar", :to => child
      end
      
      child.woot.url(:dependency).should == "/foo/something"
    end
    
  end
  
  describe "a router with an informal protocol" do
    
    it "just works" do
      authz = Rack::Router.new(:protocol => [:login]) do |r|
        r.map "/login", :to => LoginApp, :name => :login
      end

      child = Rack::Router.new

      prepare do |r|
        r.map "/hello", :to => authz
        r.map "/world", :to => child
      end

      child.url(:login).should == "/hello/login"
    end
    
  end
  
end