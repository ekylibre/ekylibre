module Ekylibre
  module Testing
    class FixtureRetriever
      ROLES = %w[zeroth first second third fourth fifth sixth seventh eighth nineth tenth].freeze
      @@truc = {}

      def initialize(model, options = {}, fixture_options = nil)
        if model && model < ApplicationRecord
          fixture_options ||= {}
          @model = fixture_options.delete(:model) || model
          @prefix = fixture_options.delete(:prefix) || @model.name.underscore.pluralize
          @table = fixture_options.delete(:table) || @model.table_name
          options = { first: normalize(options) } if options && !options.is_a?(Hash)
          @options = options || {}
        end
      end

      def retrieve(role = :first, default_value = nil)
        if @model
          "#{@table}(#{normalize(@options[role] || default_value || role).inspect})"
        else
          raise 'No valid model given, cannot retrieve fixture from that'
        end
      end

      def invoke(role = :first, default_value = nil)
        if @model
          [@table.to_s, normalize(@options[role] || default_value || role)]
        else
          raise 'No valid model given, cannot retrieve fixture from that'
        end
      end

      protected

        def normalize(value)
          if value.is_a?(Integer)
            unless @@truc[@table]
              @@truc[@table] = YAML.load_file(Rails.root.join('test', 'fixtures', "#{@table}.yml")).each_with_object({}) do |pair, hash|
                hash[pair.second['id'].to_i] = pair.first.to_sym
                hash
              end
            end
            unless name = @@truc[@table][value]
              raise "Cannot find fixture in #{@table} with id=#{value.inspect}"
            end

            name
          elsif value.is_a?(Symbol)
            if ROLES.include?(value.to_s)
              "#{@prefix}_#{ROLES.index(value.to_s).to_s.rjust(3, '0')}".to_sym
            elsif value.to_s =~ /^\d+$/
              "#{@prefix}_#{value.to_s.rjust(3, '0')}".to_sym
            else
              value
            end
          elsif value.is_a?(CodeString)
            value
          else
            raise "What kind of value (#{value.class.name}:#{value.inspect})"
          end
        end
    end
  end
end
