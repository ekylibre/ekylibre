module Nomen
  module Migration
    module Actions
      class Base
        def self.action_name
          name.split('::').last.underscore
        end

        def action_name
          self.class.action_name
        end
      end
    end
  end
end
