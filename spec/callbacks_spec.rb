require 'spec_helper'

describe 'attribute_callbacks plugin' do
  include_context 'database'
  
  before :all do
    @db.execute "CREATE EXTENSION IF NOT EXISTS hstore"
    @db.create_table :widgets do
      primary_key :id
      String :name
      column :colors, 'text[]'
      column :store, :hstore
    end
  end
  
  before do
    db.execute "TRUNCATE TABLE widgets"
    db.extension:pg_array
    db.extension:pg_hstore
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
    context "with an array" do
      it "are called when an instance is being modified" do
        i = model.create colors: ['red']
        i.should_receive(:before_colors_add).with('blue').and_return true
        i.colors += ['blue']
        i.save.should be
        model.first.colors.should == ['red', 'blue']
      end

      describe "and an initializer" do
        let(:model) do
          class Widget < Sequel::Model
            plugin :attribute_callbacks
            def initialize _ = {}
              super _

              self.colors ||= [].pg_array
            end
          end
          Widget
        end

        it "works too" do
          i = model.create colors: ['red']
          i = model.first
          i.should_receive(:before_colors_add).with('blue').and_return true
          i.colors << 'blue'
          i.save.should be
          model.first.colors.should == ['red', 'blue']
        end
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
    end
    
    context "with an hstore" do
      it "are called when an instance is being modified" do
        i = model.create store: {a: 5}
        i.should_receive(:before_store_add).with('b', '6').and_return true
        i.store = i.store.merge b: 6
        i.save.should be
        model.first.store.should == {'a' => '5', 'b' => '6'}
      end
      
      it "work with in place modification" do
        i = model.create store: {a: 5}
        i.should_receive(:before_store_add).with('b', '6').and_return true
        i.will_change_column :store
        i.store[:b] = 6
        i.save.should be
        model.first.store.should == {'a' => '5', 'b' => '6'}
      end
      
      it "work with in place modification without will_change_column" do
        i = model.create store: {a: 5}
        i.should_receive(:before_store_add).with('b', '6').and_return true
        i.store[:b] = 6
        i.save.should be
        model.first.store.should == {'a' => '5', 'b' => '6'}
      end
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
    it "work with hstore" do
      i = model.create store: {a: 5}
      i.should_receive(:before_store_remove).with('a', '5').and_return true
      i.store = {}
      i.save.should be
      model.first.store.should == {}
    end

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
    it "work with hstore" do
      i = model.create store: {a: 5}
      i.should_receive(:after_store_add).with('b', '6').and_return true
      i.store = i.store.merge b: 6
      i.save.should be
      model.first.store.should == {'a' => '5', 'b' => '6'}
    end
      
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
    it "work with hstore" do
      i = model.create store: {a: 5}
      i.should_receive(:after_store_remove).with('a', '5').and_return true
      i.store = {}
      i.save.should be
      model.first.store.should == {}
    end
    
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
  
  it "reports store changes as remove then add" do
    i = model.create store: {a: 5}
    i.should_receive(:before_store_remove).with('a', '5').and_return true
    i.should_receive(:before_store_add).with('a', '6').and_return true
    i.store[:a] = 6
    i.save.should be
    model.first.store.should == {'a' => '6'}
  end
end
