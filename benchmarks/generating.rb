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
  column :one,   :title => "rack-router"
  column :two,   :title => "merb routing"
  column :three, :title => "rails routing"
  column :diff, :title => "rack vs. merb", :compare => [:two, :one]
  
  group "Route generation" do
  
    report "A simple string" do
      one { router.url(:string) }
      two { Merb::Router.url(:string, {}, {}) }
      three { rails.string_path }
    end
      
    report "A simple string with query parameters" do
      one { router.url(:string, :foo => "bar") }
      two { Merb::Router.url(:string, {:foo => "bar"}, {}) }
      three { rails.string_path(:foo => "bar") }
    end
      
    report "A couple variable segments" do
      one { router.url(:captures, :foo => "one", :bar => "two") }
      two { Merb::Router.url(:string, {:foo => "one", :bar => "two"}, {}) }
      three { rails.captures_path(:foo => "foo", :bar => "bar") }
    end
      
    report "A lot of variable segments" do
      one { router.url(:lots_o_captures, :one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6") }
      two { Merb::Router.url(:lots_o_captures, {:one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6"}, {}) }
      three { rails.lots_o_captures_path(:one => "1", :two => "2", :three => "3", :four => "4", :five => "5", :six => "6") }
    end
      
    report "A route with conditions that matches" do
      one { router.url(:conditions, :one => "1", :two => "2", :three => "3") }
      two { Merb::Router.url(:conditions, {:one => "1", :two => "2", :three => "3"}, {}) }
      three { rails.conditions_path(:one => "1", :two => "2", :three => "3") }
    end
      
    report "A route with conditions that don't match" do
      one { router.url(:conditions, :one => "one", :two => "two", :three => "three") rescue nil }
      two { Merb::Router.url(:conditions, {:one => "one", :two => "two", :three => "three"}, {}) rescue nil }
      three { rails.conditions_path(:one => "one", :two => "two", :three => "three") rescue nil }
    end
      
    # ==== Defaults
    report "A route with defaults while specifying all the parameters" do
      one { router.url(:defaults, :one => "one", :two => "two", :three => "three") }
      two { Merb::Router.url(:defaults, {:one => "one", :two => "two", :three => "three"}, {}) }
      three { rails.defaults_path(:one => "one", :two => "two", :three => "three") }
    end
      
    report "A route with defaults while specifying the last parameter" do
      one { router.url(:defaults, :three => "three") }
      two { Merb::Router.url(:defaults, {:three => "three"}, {}) }
      three { rails.defaults_path(:three => "three") }
    end
      
    report "A route with defaults while specifying the first parameter" do
      one { router.url(:defaults, :one => "one") }
      two { Merb::Router.url(:defaults, {:one => "one"}, {}) }
      three { rails.defaults_path(:one => "one") }
    end
      
    report "A route with defaults while specifying none of the parameters" do
      one { router.url(:defaults) }
      two { Merb::Router.url(:defaults, {}, {}) }
      three { rails.defaults_path }
    end
  
    # ==== Optionals
    report "A route with optional segments given only the first parameter" do
      one { router.url(:optionals, :controller => "foo") }
      two { Merb::Router.url(:optionals, {:controller => "foo"}, {}) }
      three { rails.url_for(:controller => "foo") }
    end
  
    report "A route with optional segments given two sequential optional parameters" do
      one { router.url(:optionals, :controller => "foo", :format => "js") }
      two { Merb::Router.url(:optionals, {:controller => "foo", :format => "js"}, {}) }
      three { rails.url_for(:controller => "foo", :format => "js") }
    end
  
    report "A route with optional segments given two nested optional parameters" do
      one { router.url(:optionals, :controller => "foo", :action => "bar") }
      two { Merb::Router.url(:optionals, {:controller => "foo", :action => "bar"}, {}) }
      three { rails.url_for(:controller => "foo", :action => "bar") }
    end
  
    report "A route with optional segments given two nested optional parameters and one sequential" do
      one { router.url(:optionals, :controller => "foo", :action => "bar", :format => "js") }
      two { Merb::Router.url(:optionals, {:controller => "foo", :action => "bar", :format => "js"}, {}) }
      three { rails.url_for(:controller => "foo", :action => "bar", :format => "js") }
    end
  
    report "A route with optional segments given three nested optional parameters" do
      one { router.url(:optionals, :controller => "foo", :action => "bar", :id => "10") }
      two { Merb::Router.url(:optionals, {:controller => "foo", :action => "bar", :id => "10"}, {}) }
      three { rails.url_for(:controller => "foo", :action => "bar", :id => "10") }
    end
  
    report "A route with optional segments given all the parameters" do
      one { router.url(:optionals, :controller => "foo", :action => "bar", :id => "10", :format => "js") }
      two { Merb::Router.url(:optionals,{ :controller => "foo", :action => "bar", :id => "10", :format => "js"}, {}) }
      three { rails.url_for(:controller => "foo", :action => "bar", :id => "10", :format => "js") }
    end
  
    # ==== Optionals & Defaults
    report "A route with optionals & defaults while specifying all the parameters" do
      one { router.url(:opts_with_defaults, :one => "one", :two => "two", :three => "three") }
      two { Merb::Router.url(:opts_with_defaults, {:one => "one", :two => "two", :three => "three"}, {}) }
    end
  
    report "A route with optionals & defaults while specifying the last parameter" do
      one { router.url(:opts_with_defaults, :three => "three") }
      two { Merb::Router.url(:opts_with_defaults, {:three => "three"}, {}) }
    end
  
    report "A route with optionals & defaults while specifying the first parameter" do
      one { router.url(:opts_with_defaults, :one => "one") }
      two { Merb::Router.url(:opts_with_defaults, {:one => "one"}, {}) }
    end
  
    report "A route with optionals & defaults while specifying none of the parameters" do
      one { router.url(:opts_with_defaults) }
      two { Merb::Router.url(:opts_with_defaults, {}, {}) }
    end
    
    summary "All route generation (totals)"
  end
end