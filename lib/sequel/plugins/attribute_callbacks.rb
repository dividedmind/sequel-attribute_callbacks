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
          call_attribute_hook column, change
        end
      end

      def after_create
        super

        columns.each do |column|
          value = send column
          call_attribute_hook column, [nil, value] if column
        end
      end
      
      private
      def call_attribute_hook column, change
        method = "#{column}_changed".to_sym
        send method, *change if respond_to? method
      end
    end
  end
end
