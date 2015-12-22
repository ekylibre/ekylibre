module Nomen
  module Migration
    module Actions
      class ItemRemoval < Nomen::Migration::Actions::Base
        attr_reader :nomenclature, :name
        def initialize(element)
          name = element['item'].split('#')
          @nomenclature = name.first
          @name = name.second
        end

        def human_name
          "Remove item #{@nomenclature}##{@name}"
        end
      end
    end
  end
end
