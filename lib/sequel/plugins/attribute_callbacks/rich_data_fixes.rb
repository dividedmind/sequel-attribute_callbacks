module Sequel::Plugins::AttributeCallbacks
  module DelegatorDeepClone
    # Delegator clone method doesn't clone the delegated to object
    # which makes it impossible for the Dirty plugin track changes
    def clone
      c = super
      c.__setobj__ __getobj__.clone
      c
    end
  end

  module RichDataCloner
    module InstanceMethods
      def after_initialize
        super
        clone_rich_attributes
      end
      
      def after_save
        super
        clone_rich_attributes
      end
      
      private
      
      # those are often going to be modified in place
      def clone_rich_attributes
        values.each do |name, value|
          if value.kind_of?(Sequel::Postgres::PGArray) || value.kind_of?(Sequel::Postgres::HStore)
            initial_values[name] = value.clone
          end
        end
      end
    end
  end
end

Sequel::Postgres::PGArray.send :include, Sequel::Plugins::AttributeCallbacks::DelegatorDeepClone if defined? Sequel::Postgres::PGArray
Sequel::Postgres::HStore.send :include, Sequel::Plugins::AttributeCallbacks::DelegatorDeepClone if defined? Sequel::Postgres::HStore
