require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests" do
  
  describe "a anchored route that maps to a rewritten PATH_INFO" do
    
    it "changes the PATH_INFO to what is specified when the route matches" do
      prepare do |r|
        r.map "/hello", :to => HelloApp, :at => "/greetings"
      end
      
      route_for("/hello").should have_env("PATH_INFO" => "/greetings", "SCRIPT_NAME" => "/hello")
    end
    
    it "does not leak PATH_INFO across rewritten routes that do not match" do
      prepare do |r|
        r.map "/hello/world", :to => lambda { Rack::Router::NOT_FOUND_RESPONSE }, :at => "/omgfail"
        r.map "/hello/world", :to => HelloApp
      end
      
      route_for("/hello/world").should have_env("PATH_INFO" => "", "SCRIPT_NAME" => "/hello/world")
    end
    
  end
  
  describe "an unanchored route that maps to a rewritten PATH_INFO" do
    
    it "changes the PATH_INFO to what is specified when the route matches, discarding the remaining unconsumed PATH_INFO" do
      prepare do |r|
        r.map "/hello", :to => HelloApp, :at => "/greetings", :anchor => false
      end
      
      route_for("/hello/world").should have_env("PATH_INFO" => "/greetings", "SCRIPT_NAME" => "/hello")
    end
    
  end
  
end