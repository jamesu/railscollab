require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdministrationTool do
  before(:each) do
    @attributes = { :name => 'test tool', :controller => 'user', :action => 'avatar', :order => 1 }
    @tool = AdministrationTool.create!(@attributes)
  end

  it 'should create a new instance given valid attributes' do
    @tool.name.should       == @attributes[:name]
    @tool.controller.should == @attributes[:controller]
    @tool.action.should     == @attributes[:action]
    @tool.order.should      == @attributes[:order]
  end

  it 'should return a proper object url' do
    @tool.object_url.should == "/#{@attributes[:controller]}/#{@attributes[:action]}"
  end

  it 'should return a list of all admin tools' do
    @attributes[:name] = '2nd tool'
    tool2 = AdministrationTool.create!(@attributes)

    AdministrationTool.admin_list.should have(2).entries
    AdministrationTool.admin_list.should include(@tool)
    AdministrationTool.admin_list.should include(tool2)
  end

  it 'should return a proper display name'
  it 'should return a proper display description'
end
