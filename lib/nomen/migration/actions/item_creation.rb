module Nomen
  module Migration
    module Actions
      class ItemCreation < Nomen::Migration::Actions::Base
        attr_reader :nomenclature, :name, :options
        def initialize(element)
          name = element['item'].split('#')
          @nomenclature = name.first
          @name = name.second
          @options = element.attributes.delete_if do |k, _v|
            k =~ /name(:[a-z]{3})?/ || %w(item parent nomenclature).include?(k)
          end
          @options[:parent] = element['parent'].to_sym if element.key?('parent')
        end

        def options?
          @options.any?
        end

        def human_name
          updates = []
          updates << "#{@name} as name"
          updates << "#{@parent} as parent" if parent?
          @options.each do |k, v|
            updates << "#{v} as #{k}"
          end
          sentence = "Create item #{@nomenclature}##{@name} with " + updates.to_sentence
        end
      end
    end
  end
end
