module Sequel::Plugins::AttributeCallbacks
  module PgArrayFixes
    module PgArray
      # Delegator clone method doesn't clone the delegated to object
      # which makes it impossible for the Dirty plugin track changes
      def clone
        c = super
        c.__setobj__ __getobj__.clone
        c
      end
    end
    
    module AttributeCallbacks
      def after_initialize
        super
        clone_array_attributes
      end
      
      def after_save
        super
        clone_array_attributes
      end
      
      private
      
      # arrays are probably going to be often modified in place
      def clone_array_attributes
        values.each do |name, value|
          if value.kind_of? Sequel::Postgres::PGArray
            initial_values[name] = value.clone
          end
        end
      end
    end
  end
end

Sequel::Postgres::PGArray.send :include, Sequel::Plugins::AttributeCallbacks::PgArrayFixes::PgArray if defined? Sequel::Postgres::PGArray
