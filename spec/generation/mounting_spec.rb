require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  describe "a child router mounted with no conditions" do
    
    before(:each) do
      @child  = router { |r| r.map "/child", :to => ChildApp, :name => :child }
      @parent = router { |r| r.map :to => @child, :name => :child }
    end
    
    it "generates URLs when mounted in a parent" do
      @child.url(:child).should == "/child"
    end
    
    it "provides the child router from the parent" do
      @parent.child.url(:child).should == "/child"
    end
    
    it "raises an exception when trying to generate the child routes from the parent" do
      lambda { @parent.url(:child) }.should raise_error(ArgumentError)
    end
    
  end
  
  describe "a child router mounted at a path location" do
    
    before(:each) do
      @child  = router { |r| r.map "/child", :to => ChildApp, :name => :child }
      @parent = router { |r| r.map "/kidz", :to => @child, :name => :child }
    end
    
    it "generates URLs in context of the mount point" do
      @child.url(:child).should == "/kidz/child"
    end
    
  end
  
end

describe "FAK" do

  before(:each) do
    pending
  end
  
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