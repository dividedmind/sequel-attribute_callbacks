require 'sequel'

module Sequel::Plugins
  module AttributeCallbacks
    def self.apply model
      model.plugin :dirty
    end
    
    module InstanceMethods
      def after_save
        (previous_changes || []).each do |column, change|
          method = "#{column}_changed".to_sym
          self.send method, *change if respond_to? method
        end
        
        super
      end
    end
  end
end
