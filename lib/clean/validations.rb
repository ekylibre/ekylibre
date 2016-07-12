module Clean
  module Validations
    class << self
      def validable_column?(column)
        return false if [:created_at, :creator_id, :creator, :updated_at, :updater_id, :updater, :position, :lock_version].include?(column.name.to_sym)
        return false if column.name.to_s =~ /^\_/
        true
      end

      def search_missing_validations(model)
        code = ''

        return code unless model.superclass == Ekylibre::Record::Base

        record = model.name.underscore

        columns = model.content_columns.delete_if { |c| !validable_column?(c) }.sort { |a, b| a.name.to_s <=> b.name.to_s }

        cs = columns.select { |c| c.type == :date }
        if cs.any?
          code << '  validates ' + cs.map { |c| ":#{c.name}" }.join(', ') + ", timeliness: { allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }\n"
        end

        cs = columns.select { |c| c.type == :datetime || c.type == :timestamp }
        if cs.any?
          code << '  validates ' + cs.map { |c| ":#{c.name}" }.join(', ') + ", timeliness: { allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }\n"
        end

        columns.each do |c|
          next unless [:stopped_at, :stopped_on].include?(c.name.to_sym)
          # p "started#{c.name.scan(/_.{2}/).first}", columns.collect(&:name)
          suffix = c.name.scan(/_.{2}/).first
          if suffix && columns.collect(&:name).include?("started#{suffix}")
            code << "  validates :#{c.name}, timeliness: { allow_blank: true, on_or_after: :started#{suffix} }, if: ->(#{record}) { #{record}.#{c.name} && #{record}.started#{suffix} }\n"
          end
        end

        cs = columns.select { |c| c.type == :integer }
        if cs.any?
          code << '  validates ' + cs.map { |c| ":#{c.name}" }.join(', ') + ", numericality: { allow_nil: true, only_integer: true }\n"
        end

        cs = columns.select { |c| c.number? && c.type != :integer }
        if cs.any?
          code << '  validates ' + cs.map { |c| ":#{c.name}" }.join(', ') + ", numericality: { allow_nil: true }\n"
        end

        cs = columns.select { |c| (c.type == :string || c.type == :text) && c.limit }
        limits = cs.map(&:limit).uniq.sort # .delete_if{|l| l == 255}
        limits.each do |limit|
          cs = columns.select { |c| c.limit == limit }
          code << '  validates ' + cs.map { |c| ":#{c.name}" }.join(', ') + ", numericality: { allow_nil: true, maximum: #{limit} }\n"
        end

        cs = columns.select { |c| !c.null && c.type == :boolean }
        if cs.any?
          code << '  validates ' + cs.map { |c| ":#{c.name}" }.join(', ') + ", inclusion: { in: [true, false] }\n"
        end

        needed = columns.select { |c| !c.null && c.type != :boolean }.map { |c| ":#{c.name}" }
        needed += model.reflect_on_all_associations(:belongs_to).select do |association|
          column = model.columns_hash[association.foreign_key.to_s]
          unless column
            raise StandardError, "Problem in #{association.active_record.name} at '#{association.macro} :#{association.name}'"
          end
          !column.null && validable_column?(column)
        end.map { |r| ":#{r.name}" }
        code << '  validates ' + needed.sort.join(', ') + ", presence: true\n" if needed.any?

        code
      end
    end
  end
end
