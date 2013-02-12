require 'spec_helper'

describe Sequel::Plugins::AttributeCallbacks do
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
end
