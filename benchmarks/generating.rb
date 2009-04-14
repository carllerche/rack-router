require File.join(File.dirname(__FILE__), 'setup')

router = Rack::Router.new(nil) do |r|
  r.map "/hello",                                 :to => SuccessApp, :name => :string
  r.map "/:foo/:bar",                             :to => SuccessApp, :name => :captures
  r.map "/:one/:two/:three/:four/:five/:six",     :to => SuccessApp, :name => :lots_o_captures
  r.map "/:one/:two/:three",                      :to => SuccessApp, :name => :conditions, :conditions => { :one => /\d+/, :two => /\d+/, :three => /\d+/ }
  r.map "/:one/:two/:three",                      :to => SuccessApp, :name => :defaults, :with => { :one => "1", :two => "2", :three => "3" }
  r.map "/:controller(/:action(/:id))(.:format)", :to => SuccessApp, :name => :optionals
  r.map "/:one(/:two(/:three))",                  :to => SuccessApp, :name => :opts_with_defaults, :with => { :one => "1", :two => "2", :three => "3" }
end

Merb::Router.prepare do
  with(:controller => "success") do
    match("/hello").name(:string)    
    match("/:foo/:bar").name(:captures)                           
    match("/:one/:two/:three/:four/:five/:six").name(:lots_o_captures)
    match("/:one/:two/:three", :one => /\d+/, :two => /\d+/, :three => /\d+/).name(:conditions)
    match("/(:one/:two/:three)").defaults(:one => "1", :two => "2", :three => "3").name(:defaults)
    match("/:controller(/:action(/:id))(.:format)").name(:optionals)
    match("/:one(/:two(/:three))").defaults(:one => "1", :two => "2", :three => "3").name(:opts_with_defaults)
  end
end

RBench.run(10_000) do
  column :one, :title => "rack-router"
  column :two, :title => "merb routing"
  
  report "Generating a simple string" do
    one { router.url(:string) }
    two { Merb::Router.url(:string, {}, {}) }
  end
  
  report "Generating a simple string with query parameters" do
    one { router.url(:string, :foo => "bar") }
    two { Merb::Router.url(:string, {:foo => "bar"}, {}) }
  end
  
  report "Generating a couple variable segments" do
    one { router.url(:captures, :foo => "one", :bar => "two") }
    two { Merb::Router.url(:string, {:foo => "one", :bar => "two"}, {}) }
  end
  
  report "Generating a lot of variable segments" do
    one { router.url(:lots_o_captures, :one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6") }
    two { Merb::Router.url(:lots_o_captures, {:one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6"}, {}) }
  end
  
  report "Generating a route with conditions that matches" do
    one { router.url(:conditions, :one => "1", :two => "2", :three => "3") }
    two { Merb::Router.url(:conditions, {:one => "1", :two => "2", :three => "3"}, {}) }
  end
  
  report "Generating a route with conditions that don't match" do
    one { router.url(:conditions, :one => "one", :two => "two", :three => "three") rescue nil }
    two { Merb::Router.url(:conditions, {:one => "one", :two => "two", :three => "three"}, {}) rescue nil }
  end
  
  # ==== Defaults
  report "Generating a route with defaults while specifying all the parameters" do
    one { router.url(:defaults, :one => "one", :two => "two", :three => "three") }
    two { Merb::Router.url(:defaults, {:one => "one", :two => "two", :three => "three"}, {}) }
  end
  
  report "Generating a route with defaults while specifying the last parameter" do
    one { router.url(:defaults, :three => "three") }
    two { Merb::Router.url(:defaults, {:three => "three"}, {}) }
  end
  
  report "Generating a route with defaults while specifying the first parameter" do
    one { router.url(:defaults, :one => "one") }
    two { Merb::Router.url(:defaults, {:one => "one"}, {}) }
  end
  
  report "Generating a route with defaults while specifying none of the parameters" do
    one { router.url(:defaults) }
    two { Merb::Router.url(:defaults, {}, {}) }
  end
  
  # ==== Optionals
  report "Generating a route with optional segments given only the first parameter" do
    one { router.url(:optionals, :controller => "foo") }
    two { Merb::Router.url(:optionals, {:controller => "foo"}, {}) }
  end
  
  report "Generating a route with optional segments given all the parameters" do
    one { router.url(:optionals, :controller => "foo", :action => "bar", :id => "10", :format => "js") }
    two { Merb::Router.url(:optionals,{ :controller => "foo", :action => "bar", :id => "10", :format => "js"}, {}) }
  end
end