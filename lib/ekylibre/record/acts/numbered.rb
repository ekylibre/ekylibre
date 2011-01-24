module Ekylibre::Record
  module Acts #:nodoc:
    module Numbered #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Use preference to select preferred sequence to attribute number
        # in column
        def acts_as_numbered(column=:number, options = {})
          # Bugs with MSSQL
          # raise ArgumentError.new("Method #{column.inspect} must be an existent column of the table #{self.table_name}") unless self.columns_hash.has_key? column.to_s
          options = {:first_value=>'00000001'}.merge(options)


          sequence = options[:sequence] || "#{self.name.underscore.pluralize}_sequence"

          last = "self.company.#{self.name.underscore.pluralize}.find(:first, :conditions=>['#{column} IS NOT NULL'], :order=>#{self.name}.connection.length('#{column}')+' DESC, #{column} DESC')"

          code = ""

          code += "attr_readonly :#{column}\n" unless options[:readonly].is_a? FalseClass

          code += "validates_presence_of :#{column}\n"

          code += "validates_uniqueness_of :#{column}, :scope=>:company_id\n"

          code += "before_validation(:on=>:create) do\n"
          code += "  if self.company\n"
          code += "    last = #{last}\n"
          code += "    self.#{column} = (last ? last.#{column}.succ : #{options[:first_value].inspect})\n"
          code += "  else\n"
          max = self.columns_hash[column.to_s].limit||64
          code += "    self.#{column} = Time.now.to_i.to_s(36)[0..#{max-1}]\n"
          code += "    (#{max}-self.#{column}.size).times { self.#{column} += (36*rand).to_i.to_s(36) }\n"
          code += "  end\n"
          code += "  return true\n"
          code += "end\n"

          code += "after_validation(:on=>:create) do\n"
          code += "  if sequence = self.company.preferred_#{sequence}\n"
          code += "    self.#{column} = sequence.next_value\n"
          code += "  else\n"
          code += "    last = #{last}\n"
          code += "    self.#{column} = (last ? last.#{column}.succ : #{options[:first_value].inspect})\n"
          code += "  end\n"
          code += "  return true\n"
          code += "end\n"
          # puts code
          class_eval code
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Numbered)
