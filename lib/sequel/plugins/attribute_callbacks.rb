require 'sequel'

module Sequel::Plugins
  module AttributeCallbacks
    def self.apply model
      model.plugin :dirty
    end
    
    module InstanceMethods
      def before_update
        (column_changes || []).each do |column, change|
          return false unless call_before_attribute_hook column, change
        end
        super
      end
      
      def after_update
        super
        (previous_changes || []).each do |column, change|
          call_after_attribute_hook column, change
        end
      end

      def before_create
        columns.each do |column|
          value = send column
          return false unless call_before_attribute_hook column, [nil, value] if value
        end
        super
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

      def call_before_attribute_hook column, change
        method = "before_#{column}_change".to_sym
        if respond_to? method
          send method, *change
        else
          true
        end
      end
    end
  end
end
