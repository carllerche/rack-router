require File.join(File.dirname(__FILE__), 'setup')

router = Rack::Router.new(nil) do |r|
  r.map "/aa/aa", :to => SuccessApp
  r.map "/aa/bb", :to => SuccessApp
  r.map "/bb/aa", :to => SuccessApp
end

debugger

router