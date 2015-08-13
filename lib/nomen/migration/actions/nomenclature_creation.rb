module Nomen
  module Migration
    module Actions

      class NomenclatureCreation < Nomen::Migration::Actions::Base

        attr_reader :name, :options

        def initialize(element)
          fail "No given name" unless element.key?("name")
          @name = element["name"].to_s
          @options = {}
          notions = element.attr('notions').to_s.split(/\s*\,\s*/).map(&:to_sym)
          @options[:notions] = notions if notions.any?
          @options[:translateable] = !(element.attr('translateable').to_s == 'false')
        end

        def human_name
          "Create nomenclature #{@name}"
        end
      end

    end
  end
end
