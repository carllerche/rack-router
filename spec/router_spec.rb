require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Rack::Router do
  
  it "provides a list of end points" do
    prepare do |r|
      r.map "/one", :to => OneApp
      r.map "/two", :to => TwoApp
    end
    
    @app.end_points.should == [OneApp, TwoApp]
  end
  
  it "does not duplicate the end points" do
    prepare do |r|
      r.map "/one", :to => OneApp
      r.map "/foo", :to => OneApp
      r.map "/two", :to => TwoApp
    end
    
    @app.end_points.should == [OneApp, TwoApp]
  end
  
  it "raises an error if a route is created without specifying an end point" do
    lambda do
      prepare do |r|
        r.map "/hello"
      end
    end.should raise_error(ArgumentError)
  end
  
  it "raises an error if a route is created with an invalid rack application as an end point" do
    lambda do
      prepare do |r|
        r.map "/hello", :to => "HelloApp"
      end
    end.should raise_error(ArgumentError)
  end
  
end