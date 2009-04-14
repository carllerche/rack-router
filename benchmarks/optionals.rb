require File.join(File.dirname(__FILE__), 'setup')

router = Rack::Router.new(nil) do |r|
  r.map "/:controller(/:action(/:id))(.:format)", :to => SuccessApp
end

Merb::Router.prepare do
  with(:controller => "success") do
    match("/:controller(/:action(/:id))(.:format)").register
  end
end

# /:controller(/:action(/:id))(.:format)
rack_optionals_1 = env_for("/hello")
merb_optionals_1 = Merb::Request.new(rack_optionals_1)
rack_optionals_2 = env_for("/hello.js")
merb_optionals_2 = Merb::Request.new(rack_optionals_2)
rack_optionals_3 = env_for("/hello/world")
merb_optionals_3 = Merb::Request.new(rack_optionals_3)
rack_optionals_4 = env_for("/hello/world.js")
merb_optionals_4 = Merb::Request.new(rack_optionals_4)
rack_optionals_5 = env_for("/hello/world/10")
merb_optionals_5 = Merb::Request.new(rack_optionals_5)
rack_optionals_6 = env_for("/hello/world/10.js")
merb_optionals_6 = Merb::Request.new(rack_optionals_6)


RBench.run(10_000) do

  column :one, :title => "rack-router"
  column :two, :title => "merb routing"

  report "Matching /hello" do
    one { router.call(rack_optionals_1) }
    two { Merb::Router.match(merb_optionals_1) }
  end

  report "Matching /hello.js" do
    one { router.call(rack_optionals_2) }
    two { Merb::Router.match(merb_optionals_2) }
  end

  report "Matching /hello/world" do
    one { router.call(rack_optionals_3) }
    two { Merb::Router.match(merb_optionals_3) }
  end

  report "Matching /hello/world.js" do
    one { router.call(rack_optionals_4) }
    two { Merb::Router.match(merb_optionals_4) }
  end

  report "Matching /hello/world/10" do
    one { router.call(rack_optionals_5) }
    two { Merb::Router.match(merb_optionals_5) }
  end

  report "Matching /hello/world/10.js" do
    one { router.call(rack_optionals_6) }
    two { Merb::Router.match(merb_optionals_6) }
  end

end