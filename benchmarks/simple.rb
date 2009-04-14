require File.join(File.dirname(__FILE__), 'setup')

router = Rack::Router.new(nil) do |r|
  r.map "/success",   :to => SuccessApp
  r.map "/:foo/:bar", :to => SuccessApp
end

Merb::Router.prepare do
  with(:controller => "success") do
    match("/success").register
    match("/:foo/:bar").register
  end
end

# /success
rack_success = env_for("/success")
merb_success = Merb::Request.new(rack_success)

# /:foo/:bar
rack_foobar = env_for("/one/two")
merb_foobar = Merb::Request.new(rack_foobar)


RBench.run(10_000) do
  
  column :one, :title => "rack-router"
  column :two, :title => "merb routing"
  
  report "A string path" do
    one { router.call(rack_success) }
    two { Merb::Router.match(merb_success) }
  end
  
  report "A path with captures" do
    one { router.call(rack_foobar) }
    two { Merb::Router.match(merb_foobar) }
  end
  
end