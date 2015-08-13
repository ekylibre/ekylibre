module Nomen
  module Migration
    module Actions
      class ItemChange < Nomen::Migration::Actions::Base
        attr_reader :nomenclature, :name, :parent, :properties, :new_name, :new_parent, :new_properties
        def initialize(element)
          name = element['item'].split('#')
          @nomenclature = name.first
          @name = name.second
          @new_name = element['name'] if element.key?('name')
          @new_parent = element['parent'] if element.key?('parent')
          @new_properties = element.attributes.delete_if do |k, _v|
            k =~ /name(:[a-z]{3})?/ || %w(item parent nomenclature).include?(k)
          end
        end

        def new_name?
          @new_name.present?
        end

        def new_parent?
          @new_parent.present?
        end

        def new_properties?
          @new_properties.any?
        end

        def changes
          hash = new_properties || {}
          hash[:name] = new_name if new_name?
          hash[:parent] = new_parent if new_parent?
          hash
        end

        def human_name
          updates = []
          updates << "new name #{@new_name}" if new_name?
          updates << "new parent #{@new_parent}" if new_parent?
          @new_properties.each do |k, v|
            updates << "new #{k} #{v}"
          end
          sentence = "Change item #{@nomenclature}##{@name} with " + updates.to_sentence
        end
      end
    end
  end
end
