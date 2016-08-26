require 'active_support/number_helper/number_to_delimited_converter'

module Clean
  module Validations
    class << self
      def pretty_number(value)
        ActiveSupport::NumberHelper::NumberToDelimitedConverter.convert(value, locale: :eng, delimiter: '_')
      end

      def validable_column?(column)
        return false if [:created_at, :creator_id, :creator, :updated_at, :updater_id, :updater, :position, :lock_version].include?(column.name.to_sym)
        return false if column.name.to_s =~ /^\_/
        true
      end

      def search_missing_validations(model)
        return '' unless model.superclass == Ekylibre::Record::Base

        record = model.name.underscore

        columns = model.content_columns.delete_if { |c| !validable_column?(c) }.sort { |a, b| a.name.to_s <=> b.name.to_s }
        string_foreign_keys = model.nomenclature_reflections.values.map(&:foreign_key)

        validations = {}
        columns.each do |column|
          list = []

          type = column.type

          list << 'presence: true' if !column.null && type != :boolean

          if ActiveRecord::Base.connection.index_exists?(model.table_name, column.name, unique: true)
            list << 'uniqueness: true'
          end

          if [:date, :datetime, :timestamp].include? type
            suffix = column.name.scan(/_.+$/).first[1..-1]
            on_or_after = nil
            if column.name =~ /\Astopped_#{suffix}\z/ && columns.collect(&:name).include?("started_#{suffix}")
              on_or_after = "->(#{record}) { #{record}.started_#{suffix} || Time.new(1, 1, 1).in_time_zone }"
            end
            on_or_after ||= '-> { Time.new(1, 1, 1).in_time_zone }'
            list << "timeliness: { on_or_after: #{on_or_after}, on_or_before: -> { Time.zone.#{suffix == 'on' ? 'today' : 'now'} + 50.years }#{', type: :date' if type == :date} }" # #{ 'allow_blank: true, ' if column.null }
          elsif type == :boolean
            list << 'inclusion: { in: [true, false] }'
          elsif type == :integer
            list << "numericality: { only_integer: true, greater_than: -#{pretty_number(2_147_483_648 + 1)}, less_than: #{pretty_number(2_147_483_647 + 1)} }"
          elsif column.number?
            if column.precision && column.scale
              max = pretty_number(10**(column.precision - column.scale))
              list << "numericality: { greater_than: -#{max}, less_than: #{max} }"
            else
              list << 'numericality: true'
            end
          elsif type == :string || type == :text
            limit = column.limit
            # We consider nomenclature inclusion validation as sufficient
            unless string_foreign_keys.include?(column.name) ||
                   (model.respond_to?(column.name) && model.send(column.name).respond_to?(:values))
              limit ||= 500 if type == :string
              limit ||= 5 * 10**5
            end
            list << "length: { maximum: #{pretty_number(limit)} }" if limit
          end
          if column.null && list.any?
            list << 'allow_blank: true' # unless [:date, :datetime, :timestamp].include? type
          end
          next if list.empty?
          validation = list.join(', ')
          validations[validation] ||= []
          validations[validation] << column.name.to_sym
        end

        model.reflect_on_all_associations(:belongs_to).select do |association|
          column = model.columns_hash[association.foreign_key.to_s]
          unless column
            raise StandardError, "Column #{association.foreign_key} is missing. See #{association.active_record.name} at '#{association.macro} :#{association.name}'"
          end
          !column.null && validable_column?(column)
        end.each do |reflection|
          validation = 'presence: true'
          validations[validation] ||= []
          validations[validation] << reflection.name.to_sym
        end

        validations.map do |list, attributes|
          'validates ' + attributes.sort.map { |a| ":#{a}" }.join(', ') + ", #{list}\n"
        end.join.dig
      end
    end
  end
end
