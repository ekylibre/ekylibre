module Clean
  module Validations
    class << self

      def validable_column?(column)
        return false if [:created_at, :creator_id, :creator, :updated_at, :updater_id, :updater, :position, :lock_version].include?(column.name.to_sym)
        return false if column.name.to_s.match(/^\_/)
        return true
      end


      def search_missing_validations(model)
        code = ""

        return code unless model.superclass == Ekylibre::Record::Base

        columns = model.content_columns.delete_if{|c| !validable_column?(c)}.sort{|a,b| a.name.to_s <=> b.name.to_s}

        cs = columns.select{|c| c.type == :date}
        code << "  validates_date " + cs.map{|c| ":#{c.name}"}.join(', ') + ", allow_blank: true, on_or_after: Date.civil(1, 1, 1)\n" if cs.any?

        cs = columns.select{|c| c.type == :datetime or c.type == :timestamp}
        code << "  validates_datetime " + cs.map{|c| ":#{c.name}"}.join(', ') + ", allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')\n" if cs.any?

        cs = columns.select{|c| c.type == :integer}
        code << "  validates_numericality_of " + cs.map{|c| ":#{c.name}"}.join(', ') + ", allow_nil: true, only_integer: true\n" if cs.any?

        cs = columns.select{|c| c.number? and c.type != :integer}
        code << "  validates_numericality_of " + cs.map{|c| ":#{c.name}"}.join(', ') + ", allow_nil: true\n" if cs.any?

        limits = columns.select{|c| c.text? and c.limit}.map{|c| c.limit}.uniq.sort
        for limit in limits
          cs = columns.select{|c| c.text? and c.limit == limit}
          code << "  validates_length_of " + cs.map{|c| ":#{c.name}"}.join(', ') + ", allow_nil: true, maximum: #{limit}\n"
        end

        cs = columns.select{|c| not c.null and c.type == :boolean}
        code << "  validates_inclusion_of " + cs.map{|c| ":#{c.name}"}.join(', ') + ", in: [true, false]\n" if cs.any?

        needed = columns.select{|c| not c.null and c.type != :boolean}.map{|c| ":#{c.name}"}
        needed += model.reflect_on_all_associations(:belongs_to).select do |association|
          unless column = model.columns_hash[association.foreign_key.to_s]
            raise StandardError, "Problem in #{association.active_record.name} at '#{association.macro} :#{association.name}'"
          end
          !column.null and validable_column?(column)
        end.map{|r| ":#{r.name}"}
        code << "  validates_presence_of "+needed.sort.join(', ')+"\n" if needed.any?

        return code
      end

    end
  end
end

