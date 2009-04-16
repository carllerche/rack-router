require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Rack::Router do
  
  describe "mounting rack apps" do
    
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

    it "raises an exception if a single rack router app gets mounted twice" do
      lambda {
        child = router { |c| c.map "/child", :to => ChildApp, :name => :child }
        prepare do |r|
          r.map "/first",  :to => child
          r.map "/second", :to => child
        end
      }.should raise_error
    end
    
  end
  
  describe "defining conditions" do
    
    it "raises an exception if a condition has unbalanced parentheses" do
      %w'/hello(/world /hello/world) /hello((/world) /hello(/world)) /hello(/world(/fail) /hello(/world)/fail)'.each do |path|
        lambda {
          router { |r| r.map path, :to => FailApp }
        }.should raise_error(ArgumentError)
      end
    end
    
  end
  
  describe "escaping special characters in conditions" do
    
    it "allows : to be escaped" do
      prepare { |r| r.map '/hello/\:world', :to => FooApp }
      route_for('/hello/:world').should have_route(FooApp)
      route_for('/hello/fail').should be_missing
    end
    
    it "allows * to be escaped" do
      prepare { |r| r.map '/hello/\*world', :to => FooApp }
      route_for('/hello/*world').should have_route(FooApp)
      route_for('/hello/fail').should be_missing
    end
    
    it "allows ( to be escaped" do
      prepare { |r| r.map '/hello/\(world', :to => FooApp }
      route_for('/hello/\(world').should have_route(FooApp)
    end
    
    it "allows ) to be escaped" do
      prepare { |r| r.map '/hello/\)world', :to => FooApp }
      route_for('/hello/\)world').should have_route(FooApp)
    end
    
  end
  
  describe "alternate DSLs" do
    
    class ::YoDawg
      
      attr_reader :routes
      
      def self.run(options = {})
        builder = new
        yield builder
        builder.routes
      end
      
      def initialize
        @routes = []
      end
      
      def put(opts)
        raise "FAIL!" unless opts[:so_that] == "you can route while you route"
        @routes << Rack::Router::Route.new(opts[:a], nil, { :path_info => opts[:in_your] }, {}, { :yo_dawg => true }, false)
      end
      
    end
    
    it "uses the specified DSL to build the router" do
      prepare :builder => YoDawg do |i|
        i.put :a => RouterApp, :in_your => "/router", :so_that => "you can route while you route"
      end
      
      route_for("/router").should have_route(RouterApp, :yo_dawg => true)
    end
    
  end
  
  describe "conforms to rake spec" do
    before(:all) do
      prepare { |r| r.map '/hello/\:world', :to => FooApp }
    end
    
    it "returns a status code" do
      route_for('/hello/fail').should have_status_code
    end
    
    it "returns a hash of headers" do
      route_for('/hello/fail').should have_headers
    end
    
    it "returns an object with an each method for the body" do
      route_for('/hello/fail').should have_valid_body
    end
  end
  
end