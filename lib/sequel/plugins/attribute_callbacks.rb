require 'sequel'

module Sequel::Plugins
  module AttributeCallbacks
    def self.apply model
      model.plugin :dirty
    end
    
    module InstanceMethods
      def after_update
        super
        
        (previous_changes || []).each do |column, change|
          call_after_attribute_hook column, change
        end
      end

      def after_create
        super

        columns.each do |column|
          value = send column
          call_after_attribute_hook column, [nil, value] if value
        end
      end
      
      private
      def call_after_attribute_hook column, change
        method = "after_#{column}_change".to_sym
        send method, *change if respond_to? method
      end
    end
  end
end
