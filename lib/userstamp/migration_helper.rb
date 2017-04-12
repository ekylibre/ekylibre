module Userstamp
  module MigrationHelper
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def stamps(options = {})
        groups = %i[time user lock]
        groups &= [options.delete(:only)].flatten if options[:only]
        groups -= [options.delete(:except)].flatten if options[:except]
        if groups.include?(:time)
          datetime(:created_at, null: false)
          datetime(:updated_at, null: false)
          index(:created_at)
          index(:updated_at)
        end
        if groups.include?(:user)
          references(:creator, index: true)
          references(:updater, index: true)
        end
        if groups.include?(:lock)
          integer(:lock_version, null: false, default: 0)
        end
      end
    end
  end
end
