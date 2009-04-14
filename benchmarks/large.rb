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

rack_front = env_for("/long/aaa")
merb_front = Merb::Request.new(rack_front)

rack_middle = env_for("/long/bay")
merb_middle = Merb::Request.new(rack_middle)

rack_end = env_for("/long/bzz")
merb_end = Merb::Request.new(rack_end)

RBench.run(1_000) do

  column :one, :title => "rack-router"
  column :two, :title => "merb routing"

  report "The first route in a 1352 route set" do
    one { router.call(rack_front) }
    two { Merb::Router.match(merb_front) }
  end

  report "The middle route in a 1352 route set" do
    one { router.call(rack_middle) }
    two { Merb::Router.match(merb_middle) }
  end

  report "The last route in a 1352 route set" do
    one { router.call(rack_end) }
    two { Merb::Router.match(merb_end) }
  end

end