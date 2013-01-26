module Ekylibre::Record
  module Acts #:nodoc:
    module Affairable #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def acts_as_affairable
          # TODO: Make magic
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Affairable)
