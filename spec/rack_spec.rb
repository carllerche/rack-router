require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Rack::Router" do
  
  it "updates PATH_INFO and SCRIPT_NAME correctly when calling child apps" do
    prepare do |r|
      r.map "/hello", :to => HelloApp
    end
    
    route_for("/hello").should have_env("PATH_INFO" => "/", "SCRIPT_NAME" => "/hello")
  end
  
  it "updates PATH_INFO and SCRIPT_NAME correctly in child routers" do
    prepare do |r|
      r.map "/hello", :to => router { |c| c.map "/world", :to => HelloApp }
    end
    
    route_for("/hello/world").should have_env("PATH_INFO" => "/", "SCRIPT_NAME" => "/hello/world")
  end
  
  it "does not let updated PATH_INFO and SCRIPT_NAME bleed across routes" do
    prepare do |r|
      r.map "/hello", :to => router { |c| c.map "/world", :to => WorldApp }
      r.map "/hello", :to => router { |c| c.map "/america", :to => AmericaApp }
    end
    
    route_for("/hello/america").should have_env("PATH_INFO" => "/", "SCRIPT_NAME" => "/hello/america")
  end
  
end