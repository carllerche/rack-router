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
    match("(/:one/:two(/:three))").defaults(:one => "1", :two => "2", :three => "3").name(:opts_with_defaults)
  end
end

rails = draw do |map|
  map.with_options(:controller => "success") do |r|
    r.string          "/hello"
    r.captures        "/:foo/:bar"
    r.lots_o_captures "/:one/:two/:three/:four/:five/:six"
    r.conditions      "/:one/:two/:three",                 :requirements => { :one => /\d+/, :two => /\d+/, :three => /\d+/ }
    r.defaults        "/:one/:two/:three",                 :defaults     => { :one => "1",   :two => "2",   :three => "3" }
  end
  map.connect         ":controller/:action/:id"
  map.connect         ":controller/:action/:id.:format"
end

RBench.run(10_000) do
  column :times
  column :rack,   :title => "rack-router"
  column :merb,   :title => "merb routing"
  column :rails,  :title => "rails routing"
  
  group "Route generation" do
  
    report "A simple string" do
      rack { router.url(:string) }
      merb { Merb::Router.url(:string, {}, {}) }
      rails { rails.string_path }
    end
      
    report "A simple string with query parameters" do
      rack { router.url(:string, :foo => "bar") }
      merb { Merb::Router.url(:string, {:foo => "bar"}, {}) }
      rails { rails.string_path(:foo => "bar") }
    end
      
    report "A couple variable segments" do
      rack { router.url(:captures, :foo => "one", :bar => "two") }
      merb { Merb::Router.url(:string, {:foo => "one", :bar => "two"}, {}) }
      rails { rails.captures_path(:foo => "foo", :bar => "bar") }
    end
      
    report "A lot of variable segments" do
      rack { router.url(:lots_o_captures, :one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6") }
      merb { Merb::Router.url(:lots_o_captures, {:one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6"}, {}) }
      rails { rails.lots_o_captures_path(:one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6") }
    end
      
    report "Conditions that matches" do
      rack { router.url(:conditions, :one => "1", :two => "2", :three => "3") }
      merb { Merb::Router.url(:conditions, {:one => "1", :two => "2", :three => "3"}, {}) }
      rails { rails.conditions_path(:one => "1", :two => "2", :three => "3") }
    end
      
    report "Conditions that don't match" do
      rack { router.url(:conditions, :one => "one", :two => "two", :three => "three") rescue nil }
      merb { Merb::Router.url(:conditions, {:one => "one", :two => "two", :three => "three"}, {}) rescue nil }
      rails { rails.conditions_path(:one => "one", :two => "two", :three => "three") rescue nil }
    end
      
    # ==== Defaults
    report "A route with defaults while specifying all the parameters" do
      rack { router.url(:defaults, :one => "one", :two => "two", :three => "three") }
      merb { Merb::Router.url(:defaults, {:one => "one", :two => "two", :three => "three"}, {}) }
      rails { rails.defaults_path(:one => "one", :two => "two", :three => "three") }
    end
      
    report "A route with defaults while specifying the last parameter" do
      rack { router.url(:defaults, :three => "three") }
      merb { Merb::Router.url(:defaults, {:three => "three"}, {}) }
      rails { rails.defaults_path(:three => "three") }
    end
      
    report "A route with defaults while specifying the first parameter" do
      rack { router.url(:defaults, :one => "one") }
      merb { Merb::Router.url(:defaults, {:one => "one"}, {}) }
      rails { rails.defaults_path(:one => "one") }
    end
      
    report "A route with defaults while specifying none of the parameters" do
      rack { router.url(:defaults) }
      merb { Merb::Router.url(:defaults, {}, {}) }
      rails { rails.defaults_path }
    end
  
    # ==== Optionals
    report "A route with optional segments given only the first parameter" do
      rack { router.url(:optionals, :controller => "foo") }
      merb { Merb::Router.url(:optionals, {:controller => "foo"}, {}) }
      rails { rails.url_for(:controller => "foo") }
    end
  
    report "A route with optional segments given two sequential optional parameters" do
      rack { router.url(:optionals, :controller => "foo", :format => "js") }
      merb { Merb::Router.url(:optionals, {:controller => "foo", :format => "js"}, {}) }
      rails { rails.url_for(:controller => "foo", :format => "js") }
    end
  
    report "A route with optional segments given two nested optional parameters" do
      rack { router.url(:optionals, :controller => "foo", :action => "bar") }
      merb { Merb::Router.url(:optionals, {:controller => "foo", :action => "bar"}, {}) }
      rails { rails.url_for(:controller => "foo", :action => "bar") }
    end
  
    report "A route with optional segments given two nested optional parameters and one sequential" do
      rack { router.url(:optionals, :controller => "foo", :action => "bar", :format => "js") }
      merb { Merb::Router.url(:optionals, {:controller => "foo", :action => "bar", :format => "js"}, {}) }
      rails { rails.url_for(:controller => "foo", :action => "bar", :format => "js") }
    end
  
    report "A route with optional segments given three nested optional parameters" do
      rack { router.url(:optionals, :controller => "foo", :action => "bar", :id => "10") }
      merb { Merb::Router.url(:optionals, {:controller => "foo", :action => "bar", :id => "10"}, {}) }
      rails { rails.url_for(:controller => "foo", :action => "bar", :id => "10") }
    end
  
    report "A route with optional segments given all the parameters" do
      rack { router.url(:optionals, :controller => "foo", :action => "bar", :id => "10", :format => "js") }
      merb { Merb::Router.url(:optionals,{ :controller => "foo", :action => "bar", :id => "10", :format => "js"}, {}) }
      rails { rails.url_for(:controller => "foo", :action => "bar", :id => "10", :format => "js") }
    end
  
    # ==== Optionals & Defaults
    report "A route with optionals & defaults while specifying all the parameters" do
      rack { router.url(:opts_with_defaults, :one => "one", :two => "two", :three => "three") }
      merb { Merb::Router.url(:opts_with_defaults, {:one => "one", :two => "two", :three => "three"}, {}) }
      rails { rails.defaults_path(:one => "one", :two => "two", :three => "three") }
    end
  
    report "A route with optionals & defaults while specifying the last parameter" do
      rack { router.url(:opts_with_defaults, :three => "three") }
      merb { Merb::Router.url(:opts_with_defaults, {:three => "three"}, {}) }
      rails { rails.defaults_path(:three => "three") }
    end
  
    report "A route with optionals & defaults while specifying the first parameter" do
      rack { router.url(:opts_with_defaults, :one => "one") }
      merb { Merb::Router.url(:opts_with_defaults, {:one => "one"}, {}) }
      rails { rails.defaults_path(:one => "one") }
    end
  
    report "A route with optionals & defaults while specifying none of the parameters" do
      rack { router.url(:opts_with_defaults) }
      merb { Merb::Router.url(:opts_with_defaults, {}, {}) }
    end
    
    summary "All route generation (totals)"
  end
end