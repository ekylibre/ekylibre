module Nomen
  module Migration
    module Actions
      class NomenclatureChange < Nomen::Migration::Actions::Base
        attr_reader :nomenclature, :changes

        def initialize(element)
          raise 'No given name' unless element.key?('nomenclature')
          @nomenclature = element['nomenclature'].to_s
          @changes = {}
          @changes[:name] = element['name'].to_s if element.key?('name')
          if element.key?('notions')
            @changes[:notions] = element.attr('notions').to_s.split(/\s*\,\s*/).map(&:to_sym)
          end
          if element.key?('translateable')
            @changes[:translateable] = element.attr('translateable').to_s != 'false'
          end
        end

        def human_name
          "Update nomenclature #{@name} with " + changes.inspect
        end
      end
    end
  end
end
