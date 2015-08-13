module Nomen
  module Migration
    module Actions

      class ItemCreation < Nomen::Migration::Actions::Base

        attr_reader :nomenclature, :name, :properties
        def initialize(element)
          name = element["item"].split('#')
          @nomenclature = name.first
          @name = name.second
          @properties = element.attributes.delete_if do |k, v|
            k =~ /name(:[a-z]{3})?/ || %w(item parent nomenclature).include?(k)
          end
          if element.key?("parent")
            @properties[:parent_name] = element["parent"].to_sym
          end
        end

        def properties?
          @properties.any?
        end

        def human_name
          updates = []
          updates << "#{@name} as name"
          updates << "#{@parent} as parent" if parent?
          @properties.each do |k, v|
            updates << "#{v} as #{k}"
          end
          sentence = "Create item #{@nomenclature}##{@name} with " + updates.to_sentence
        end

      end

    end
  end
end
