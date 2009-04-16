require File.join(File.dirname(__FILE__), 'setup')

# ==== Rack Router ====
router = Rack::Router.new(nil) do |r|
  r.map "/success",   :to => SuccessApp
  r.map "/:foo/:bar", :to => SuccessApp
end

# ==== Merb ====
Merb::Router.prepare do
  with(:controller => "success") do
    match("/success").register
    match("/:foo/:bar").register
  end
end

# ==== Sinatra ====
class BenchmarkApp < Sinatra::Mocked
  get "/success" do
    "Hello World"
  end
  
  get "/:foo/:bar" do
    "Hello World"
  end
end

sinatra = BenchmarkApp.new

rack_success, merb_success, sinatra_success, rails_success = build_requests("/success")
rack_foobar,  merb_foobar,  sinatra_foobar,  rails_foobar  = build_requests("/one/two")

RBench.run(10_000) do
  
  column :times
  column :rack,  :title => "rack-router"
  column :merb,  :title => "merb routing"
  column :sntra, :title => "sinatra routing"
  # column :rails,  :title => "rails routing"
  
  group "Matching simple routes" do
    report "A string path" do
      rack { router.call(rack_success) }
      merb { Merb::Router.match(merb_success) }
      sntra { sinatra.call(sinatra_success) }
    end

    report "A path with captures" do
      rack { router.call(rack_foobar) }
      merb { Merb::Router.match(merb_foobar) }
      sntra { sinatra.call(sinatra_foobar) }
    end
  end
  
end