require File.join(File.dirname(__FILE__), 'setup')

methods = [:get, :post, :put, :delete]

router = Rack::Router.new(nil) do |r|
  count = 0
  ("aa".."bm").each do |first|
    ("aa".."bm").each do |second|
      r.map "/#{first}/#{second}", methods[count % 4], :to => SuccessApp
      count += 1
    end
  end
end

Merb::Router.prepare do
  count = 0
  ("aa".."bm").each do |first|
    ("aa".."bm").each do |second|
      match("/#{first}/#{second}", :method => methods[count % 4]).to(:controller => "success")
      count += 1
    end
  end
end

draw do |r|
  count = 0
  ("aa".."bm").each do |first|
    ("aa".."bm").each do |second|
      r.map "/#{first}/#{second}", :controller => "success", :conditions => { :method => methods[count % 4] }
      count += 1
    end
  end
end

rack_front = env_for("/aa/aa", :method => :get)
merb_front = Merb::Request.new(rack_front)

rack_middle = env_for("/at/at", :method => :get)
merb_middle = Merb::Request.new(rack_middle)

rack_end = env_for("/bm/bm", :method => :get)
merb_end = Merb::Request.new(rack_end)

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
  end
end