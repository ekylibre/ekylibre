module Nomen
  module Migration
    module Actions
      class ItemChange < Nomen::Migration::Actions::Base
        attr_reader :nomenclature, :name, :changes
        def initialize(element)
          name = element['item'].split('#')
          @nomenclature = name.first
          @name = name.second
          @changes = element.attributes.delete_if do |k, _v|
            k =~ /name(:[a-z]{3})?/ || %w(item).include?(k)
          end.symbolize_keys
        end

        def new_name?
          @changes[:name].present?
        end

        def new_name
          @changes[:name]
        end

        def changes
          hash = new_properties || {}
          hash[:name] = new_name if new_name?
          hash[:parent] = new_parent if new_parent?
          hash
        end

        def human_name
          "Change item #{@nomenclature}##{@name} with " + changes.to_sentence
        end
      end
    end
  end
end
