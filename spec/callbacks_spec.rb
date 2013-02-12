require 'spec_helper'

describe 'attribute_callbacks plugin' do
  include_context 'database'
  
  before do
    db.create_table :widgets do
      primary_key :id
      String :name
    end
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

  describe '<attribute>_changed callbacks' do
    it "are called when an instance is being modified" do
      i = model.create
      i.should_receive(:name_changed).with(nil, 'foo')
      i.name = 'foo'
      i.save
    end
    
    it "rolls back the change if an exception is thrown" do
      i = model.create name: "foo"
      i.should_receive(:name_changed).with("foo", "bar").and_raise Exception
      i.name = 'bar'
      expect { i.save }.to raise_error
      
      model.first.name.should == "foo"
    end
  end
end
