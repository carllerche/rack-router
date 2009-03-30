require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a mounted router with no mount point conditions" do
    
    it "allows generating child routes from the parent router" do
      parent = router do |r|
        r.map :to => router { |c| c.map "/child", :to => ChildApp, :name => :child }
      end

      parent.url(:child).should == "/child"
    end

    it "allows generating parent routes from the child router" do
      child = router { |r| r.map "/child", :to => ChildApp, :name => :child }

      prepare do |r|
        r.map "/parent", :to => ParentApp, :name => :parent
        r.map :to => child
      end

      child.url(:parent).should == "/parent"
    end

    it "allows namespacing child routes from the parent router" do
      child  = router { |c| c.map "/child", :to => ChildApp, :name => :child }
      parent = router do |r|
        r.map :name => :kidz, :to => child
      end

      parent.url(:kidz_child).should == "/child"
      child.url(:child).should == "/child"
      lambda { child.url(:kidz_child) }.should raise_error(ArgumentError)
    end

    it "raises an exception if a single rack app gets mounted twice" do
      lambda {
        child = router { |c| c.map "/child", :to => ChildApp, :name => :child }
        prepare do |r|
          r.map "/first",  :to => child
          r.map "/second", :to => child
        end
      }.should raise_error
    end
    
  end
  
  describe "a mounted router with a path mount point condition" do
    
    it "respects the path prefix" do
      child  = router { |c| c.map "/child",  :to => ChildApp, :name => :child }
      parent = router { |c| c.map "/parent", :to => child,    :name => :parent }
      
      child.url(:child).should == "/parent/child"
      parent.url(:parent_child).should == "/parent/child"
    end
    
  end
  
end