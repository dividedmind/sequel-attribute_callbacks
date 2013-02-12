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
    
    it "work with in place modification" do
      i = model.create colors: ['red']
      i.should_receive(:before_colors_add).with('blue').and_return true
      i.will_change_column :colors
      i.colors << 'blue'
      i.save.should be
      model.first.colors.should == ['red', 'blue']
    end
    
    it "work with in place modification without will_change_column" do
      i = model.create colors: ['red']
      i.should_receive(:before_colors_add).with('blue').and_return true
      i.colors << 'blue'
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
  
  describe 'before_<attribute>_remove callbacks' do
    it "are called when an instance is being modified" do
      i = model.create colors: ['red']
      i.should_receive(:before_colors_remove).with('red').and_return true
      i.colors -= ['red']
      i.save.should be
      model.first.colors.should == []
    end
    
    it "cancel the change if false is returned" do
      i = model.create colors: ['red']
      i.should_receive(:before_colors_remove).with('red').and_return false
      i.colors -= ['red']
      expect { i.save }.to raise_error(Sequel::HookFailed)
      
      model.first.colors.should == ['red']
    end
  end

  describe 'after_<attribute>_add callbacks' do
    it "are called when an instance is being modified" do
      i = model.create colors: ['red']
      i.should_receive(:after_colors_add).with('blue')
      i.colors << 'blue'
      i.save.should be
      model.first.colors.should == ['red', 'blue']
    end

    it "are called when an instance is being created" do
      model.any_instance.should_receive(:after_colors_add).with('red')
      model.any_instance.should_receive(:after_colors_add).with('blue')
      i = model.create colors: ['red', 'blue']
    end

    it "cancel the change if an exception is thrown" do
      i = model.create colors: ['red']
      i.should_receive(:after_colors_add).with('blue').and_raise Exception
      i.colors << 'blue'
      expect { i.save }.to raise_error
      
      model.first.colors.should == ['red']
    end
  end
  
  describe 'after_<attribute>_remove callbacks' do
    it "are called when an instance is being modified" do
      i = model.create colors: ['red']
      i.should_receive(:after_colors_remove).with('red')
      i.colors -= ['red']
      i.save.should be
      model.first.colors.should == []
    end
    
    it "cancel the change if an exception is thrown" do
      i = model.create colors: ['red']
      i.should_receive(:after_colors_remove).with('red').and_raise Exception
      i.colors -= ['red']
      expect { i.save }.to raise_error
      
      model.first.colors.should == ['red']
    end
  end
end
