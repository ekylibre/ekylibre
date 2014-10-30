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

        cs = columns.select{|c| c.type == :integer}
        code << "  validates_numericality_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", allow_nil: true, only_integer: true\n" if cs.size > 0

        cs = columns.select{|c| c.number? and c.type != :integer}
        code << "  validates_numericality_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", allow_nil: true\n" if cs.size > 0

        limits = columns.select{|c| c.text? and c.limit}.collect{|c| c.limit}.uniq.sort
        for limit in limits
          cs = columns.select{|c| c.text? and c.limit == limit}
          code << "  validates_length_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", allow_nil: true, maximum: #{limit}\n"
        end

        cs = columns.select{|c| not c.null and c.type == :boolean}
        code << "  validates_inclusion_of "+cs.collect{|c| ":#{c.name}"}.join(', ')+", in: [true, false]\n" if cs.size > 0 # , :message => 'activerecord.errors.messages.blank'.to_sym

        needed = columns.select{|c| not c.null and c.type != :boolean}.collect{|c| ":#{c.name}"}
        needed += model.reflect_on_all_associations(:belongs_to).select do |association|
          column = model.columns_hash[association.foreign_key.to_s]
          raise StandardError.new("Problem in #{association.active_record.name} at '#{association.macro} :#{association.name}'") if column.nil?
          !column.null and validable_column?(column)
        end.collect{|r| ":#{r.name}"}
        code << "  validates_presence_of "+needed.sort.join(', ')+"\n" if needed.size > 0

        return code
      end

    end
  end
end

