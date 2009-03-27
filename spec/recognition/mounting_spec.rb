require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When recognizing requests" do
  
  it "can mount a child router" do
    prepare do |r|
      r.map :to => router { |c| c.map "/hello", :to => ChildApp }
      r.map "/hello", :to => ParentApp
    end
    
    route_for("/hello").should have_route(ChildApp)
  end
  
  it "respects the conditions on the mount point when handling child routers" do
    prepare do |r|
      r.map :conditions => { :host => "awesome.com" }, :to => router { |c| c.map "/hello", :to => AwesomeApp }
      r.map "/hello", :to => NotAwesomeApp
    end
    
    route_for("/hello", :host => "awesome.com").should have_route(AwesomeApp)
    route_for("/hello", :host => "lame-o.com").should have_route(NotAwesomeApp)
    route_for("/hello").should have_route(NotAwesomeApp)
  end
  
  it "can map a child router at the root path" do
    prepare do |r|
      r.map "/", :to => router { |c| c.map "/hello", :to => ChildApp }
      r.map "/hello", :to => ParentApp
    end
    
    route_for("/hello").should have_route(ChildApp)
    route_for("/").should be_missing
  end
  
  it "handles combining paths when mounting routers" do
    prepare do |r|
      r.map "/hello", :to => router { |c| c.map "/world", :to => FooApp }
    end
    
    route_for("/hello/world").should have_route(FooApp)
    # route_for("/hello").should be_missing
    # route_for("/world").should be_missing
  end
  
end