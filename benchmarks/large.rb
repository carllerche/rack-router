require File.join(File.dirname(__FILE__), 'setup')

# ==== Rack Router ====
router = Rack::Router.new(nil) do |r|
  ("aaa".."bzz").each do |path|
    r.map "/long/#{path}", :to => SuccessApp
  end
end

# ==== Merb ====
Merb::Router.prepare do
  with(:controller => "success") do
    ("aaa".."bzz").each do |path|
      match("/long/#{path}").register
    end
  end
end

# ==== Sinatra ====
class BenchmarkApp < Sinatra::Mocked
  ("aaa".."bzz").each do |path|
    get "/long/#{path}" do
      "Hello from #{path}"
    end
  end
end

sinatra = BenchmarkApp.new

# ==== Rails ====
draw do |r|
  ("aaa".."bzz").each do |path|
    r.map "/long/#{path}", :controller => "success"
  end
end

rack_front, merb_front, sinatra_front, rails_front = build_requests("/long/aaa")
rack_mid, merb_mid, sinatra_mid, rails_mid = build_requests("/long/bay")
rack_end, merb_end, sinatra_end, rails_end = build_requests("/long/bzz")

RBench.run(1_000) do

  column :times
  column :rack,  :title => "rack-router"
  column :merb,  :title => "merb routing"
  column :sntra, :title => "sinatra routing"
  column :rails, :title => "rails routing"
  
  group "A 1352 route set with routes sequential at the top level" do
    report "Matching the first route" do
      rack  { router.call(rack_front) }
      merb  { Merb::Router.match(merb_front) }
      sntra { sinatra.call(sinatra_front) }
      rails { ActionController::Routing::Routes.call(rack_front) }
    end

    report "Matching the middle route" do
      rack  { router.call(rack_mid) }
      merb  { Merb::Router.match(merb_mid) }
      sntra { sinatra.call(sinatra_mid) }
      rails { ActionController::Routing::Routes.call(rack_mid) }
    end

    report "Matching the last route" do
      rack  { router.call(rack_end) }
      merb  { Merb::Router.match(merb_end) }
      sntra { sinatra.call(sinatra_end) }
      rails { ActionController::Routing::Routes.call(rack_end) }
    end
  end
end