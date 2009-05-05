require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When generating URLs" do
  
  before(:each) do
    pending "This needs to be revisited"
  end
  
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
  
  describe "a child router mounted at a path location with a capture" do
    
    before(:each) do
      @child  = router { |r| r.map "/child", :to => ChildApp, :name => :child }
      @parent = router { |r| r.map "/:account", :to => @child, :name => :child }
    end
    
    it "generates the mounted part of the path as well" do
      @parent.child.url(:child, :account => "omg").should == "/omg/child"
    end
    
    it "raises an exception if the mounted part of the path cannot be generated with the passed parameters" do
      lambda { @parent.child.url(:child) }.should raise_error(ArgumentError)
    end
    
  end
  
end