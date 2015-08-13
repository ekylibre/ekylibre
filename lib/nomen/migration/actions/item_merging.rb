module Nomen
  module Migration
    module Actions

      class ItemMerging < Nomen::Migration::Actions::Base

        attr_reader :nomenclature, :name, :into
        def initialize(element)
          name = element["item"].split('#')
          @nomenclature = name.first
          @name = name.second
          @into = element["into"].to_s
        end

        def human_name
          "Merge item #{@nomenclature}##{@name} into #{@into}"
        end

      end

    end
  end
end
