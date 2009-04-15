require File.join(File.dirname(__FILE__), 'setup')

router = Rack::Router.new(nil) do |r|
  ("aa".."bm").each do |first|
    ("aa".."bm").each do |second|
      r.map "/#{first}/#{second}", :to => SuccessApp
    end
  end
  r.map "/lol", :to => SuccessApp
end

Merb::Router.prepare do
  ("aa".."bm").each do |first|
    ("aa".."bm").each do |second|
      match("/#{first}/#{second}").to(:controller => "success")
    end
  end
  match("/lol").to(:controller => "success")
end

draw do |r|
  ("aa".."bm").each do |first|
    ("aa".."bm").each do |second|
      r.map "/#{first}/#{second}", :controller => "success"
    end
  end
  r.map "/lol", :controller => "success"
end

rack_front = env_for("/aa/aa")
merb_front = Merb::Request.new(rack_front)

rack_middle = env_for("/at/at")
merb_middle = Merb::Request.new(rack_middle)

rack_end = env_for("/bm/bm")
merb_end = Merb::Request.new(rack_end)

rack_lol = env_for("/lol")
merb_lol = Merb::Request.new(rack_lol)

RBench.run(1_000) do

  column :times
  column :rack,   :title => "rack-router"
  column :merb,   :title => "merb routing"
  column :rails,  :title => "rails routing"
  column :diff,   :title => "rack vs. merb", :compare => [:merb, :rack]
  
  group "A 1521 route set with routes nested evenly 2 levels deep" do
    report "Matching the first route" do
      rack { router.call(rack_front) }
      merb { Merb::Router.match(merb_front) }
      rails { ActionController::Routing::Routes.call(rack_front) }
    end
    
    report "Matching the middle route" do
      rack { router.call(rack_middle) }
      merb { Merb::Router.match(merb_middle) }
      rails { ActionController::Routing::Routes.call(rack_middle) }
    end
    
    report "Matching the last route" do
      rack { router.call(rack_end) }
      merb { Merb::Router.match(merb_end) }
      rails { ActionController::Routing::Routes.call(rack_end) }
    end
    
    report "A random route at the very end" do
      rack { router.call(rack_lol) }
      merb { Merb::Router.match(merb_lol) }
      rails { ActionController::Routing::Routes.call(rack_lol) }
    end
  end
end