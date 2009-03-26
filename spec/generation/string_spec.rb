require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a plain named route with no variables" do
    
    before(:each) do
      prepare do |r|
        r.map "/hello/world", :to => FooApp, :name => :simple
      end
    end
    
  end
  
end