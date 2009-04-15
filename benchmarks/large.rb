require File.join(File.dirname(__FILE__), 'setup')

router = Rack::Router.new(nil) do |r|
  ("aaa".."bzz").each do |path|
    r.map "/long/#{path}", :to => SuccessApp
  end
end

Merb::Router.prepare do
  with(:controller => "success") do
    ("aaa".."bzz").each do |path|
      match("/long/#{path}").register
    end
  end
end

draw do |r|
  ("aaa".."bzz").each do |path|
    r.map "/long/#{path}", :controller => "success"
  end
end

rack_front = env_for("/long/aaa")
merb_front = Merb::Request.new(rack_front)

rack_middle = env_for("/long/bay")
merb_middle = Merb::Request.new(rack_middle)

rack_end = env_for("/long/bzz")
merb_end = Merb::Request.new(rack_end)

RBench.run(1_000) do

  column :times
  column :rack,   :title => "rack-router"
  column :merb,   :title => "merb routing"
  column :rails,  :title => "rails routing"
  column :diff,   :title => "rack vs. merb", :compare => [:merb, :rack]
  
  group "A 1352 route set with routes sequential at the top level" do
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
  end
end