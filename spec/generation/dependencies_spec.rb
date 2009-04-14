require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  class ::OAuthFilter
    include Rack::Router::Routable

    def initialize
      prepare do |r|
        r.map "/meta",           :get,  :to => OAuthApp, :name => :meta
        r.map "/request_tokens", :post, :to => OAuthApp, :name => :request_tokens
        r.map "/authorization",  :get,  :to => OAuthApp, :name => :authorization
      end
    end
  end
  
  class ::RoutableGreetings ; end
  RoutableGreetings.extend(Rack::Router::Routable)
  RoutableGreetings.prepare do |r|
    r.map "/hello", :to => GreetingsApp, :name => :hello
  end
  
  describe "a router with dependencies" do
    
    it "lazily binds the dependency so that URLs can be generated" do
      twitter_api = router :dependencies => { OAuthFilter => :oauth } do |r|
        r.map "/tweets", :to => TwitterAPIApp
      end
      
      prepare do |r|
        r.map "/authz", :to => OAuthFilter.new
        r.map "/api",   :to => twitter_api
      end
      
      twitter_api.oauth.url(:authorization).should == "/authz/authorization"
    end
    
    it "allows specifying class level routers as dependencies" do
      friendly = router :dependencies => { RoutableGreetings => :hi } do |r|
        r.map "/foo", :to => FooApp
      end
      
      prepare do |r|
        r.map "/friendly", :to => RoutableGreetings
        r.map "/", :to => friendly
      end
      
      friendly.hi.url(:hello).should == "/friendly/hello"
    end
    
  end
  
  describe "a router with an informal protocol" do
    
    before(:each) do
      pending "I'm not sure that this is thought out as well as it could be"
    end
    
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