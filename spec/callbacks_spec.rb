require 'spec_helper'

describe 'attribute_callbacks plugin' do
  include_context 'database'
  
  before :all do
    db.create_table :widgets do
      primary_key :id
      String :name
      column :colors, 'text[]'
    end
  end
  
  before do
    db.execute "TRUNCATE TABLE widgets"
    db.extension:pg_array
  end
  
  let(:model) { Sequel::Model(:widgets) }
  subject { model }
  
  before {
    model.instance_eval {
      plugin :attribute_callbacks
    }
  }
  
  it "doesn't interfere with record creation" do
    model.create
  end

  describe 'after_<attribute>_change callbacks' do
    it "are called when an instance is being modified" do
      i = model.create
      i.should_receive(:after_name_change).with(nil, 'foo')
      i.name = 'foo'
      i.save
    end
    
    it "are called when an instance is being created" do
      model.any_instance.should_receive(:after_name_change).with(nil, 'foo')
      i = model.create name: "foo"
    end

    it "roll back the change if an exception is thrown" do
      i = model.create name: "foo"
      i.should_receive(:after_name_change).with("foo", "bar").and_raise Exception
      i.name = 'bar'
      expect { i.save }.to raise_error
      
      model.first.name.should == "foo"
    end
  end

  describe 'before_<attribute>_change callbacks' do
    it "are called when an instance is being modified" do
      i = model.create
      i.should_receive(:before_name_change).with(nil, 'foo').and_return true
      i.name = 'foo'
      i.save.should be
      model.first.name.should == "foo"
    end
    
    it "are called when an instance is being created" do
      model.any_instance.should_receive(:before_name_change).with(nil, 'foo').and_return true
      i = model.create name: "foo"
    end

    it "cancel the change if false is returned" do
      i = model.create name: "foo"
      i.should_receive(:before_name_change).with("foo", "bar").and_return false
      i.name = 'bar'
      expect { i.save }.to raise_error(Sequel::HookFailed)
      
      model.first.name.should == "foo"
    end
  end
  
  describe 'before_<attribute>_add callbacks' do
    it "are called when an instance is being modified" do
      i = model.create colors: ['red']
      i.should_receive(:before_colors_add).with('blue').and_return true
      i.colors += ['blue']
      i.save.should be
      model.first.colors.should == ['red', 'blue']
    end
    
    it "are called when an instance is being created" do
      model.any_instance.should_receive(:before_colors_add).with('red').and_return true
      model.any_instance.should_receive(:before_colors_add).with('blue').and_return true
      i = model.create colors: ['red', 'blue']
    end

    it "cancel the change if false is returned" do
      i = model.create colors: ['red']
      i.should_receive(:before_colors_add).with('blue').and_return false
      i.colors += ['blue']
      expect { i.save }.to raise_error(Sequel::HookFailed)
      
      model.first.colors.should == ['red']
    end
  end
end
