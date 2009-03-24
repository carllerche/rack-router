require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests," do
  
  it "should match the path and return the paramters passed in" do
    prepare do |r|
      r.map "/info", :to => FooApp, :with => { :action => "info" }
    end
    
    route_for("/info").should have_route(FooApp, :action => "foo")
  end
  
end