require 'sequel'

module Sequel::Plugins
  module AttributeCallbacks
    def self.apply model
      model.plugin :dirty
      
      # require it here to make sure the pg_array extension has been loaded
      require 'sequel/plugins/attribute_callbacks/pg_array_fixes'
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
        
        scalar = if respond_to? method
          send method, *change
        else
          true
        end
        
        return false unless scalar
        
        if change.all?{|x| x.respond_to? :to_a}
          call_before_array_hooks column, *change
        else
          true
        end
      end
      
      def call_before_array_hooks column, before, after
        add_hook = "before_#{column}_add".to_sym
        rm_hook = "before_#{column}_remove".to_sym
        before = before.to_a
        after = after.to_a
        
        return false unless (after - before).all? {|x| send add_hook, x} if respond_to? add_hook
        return false unless (before - after).all? {|x| send rm_hook, x} if respond_to? rm_hook
        return true
      end
    end
  end
end
