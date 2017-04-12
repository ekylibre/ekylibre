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
            %w[item].include?(k)
          end.each_with_object({}) do |(k, v), h|
            h[k.to_sym] = (v.to_s.blank? ? nil : v.to_s)
          end
        end

        def new_name?
          @changes[:name].present?
        end

        def new_name
          @changes[:name]
        end

        def human_name
          "Change item #{@nomenclature}##{@name} with " + changes.inspect
        end
      end
    end
  end
end
