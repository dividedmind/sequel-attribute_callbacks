module Sequel::Plugins::AttributeCallbacks
  module PgArrayFixes
    # Delegator clone method doesn't clone the delegated to object
    # which makes it impossible for the Dirty plugin track changes
    def clone
      c = super
      c.__setobj__ __getobj__.clone
      c
    end
  end
end

Sequel::Postgres::PGArray.send :include, Sequel::Plugins::AttributeCallbacks::PgArrayFixes if defined? Sequel::Postgres::PGArray
