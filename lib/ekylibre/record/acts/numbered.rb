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
          options = {:start=>'00000001'}.merge(options)


          sequence = options[:sequence] || self.name.underscore.pluralize # "#{self.name.underscore.pluralize}_sequence"

          # last = "#{self.name}.find(:first, :conditions=>['#{column} IS NOT NULL'], :order=>#{self.name}.connection.length('#{column}')+' DESC, #{column} DESC')"
          last = "#{self.name}.where('#{column} IS NOT NULL').order(#{self.name}.connection.length('#{column}')+' DESC, #{column} DESC').first"

          code = ""

          code << "attr_readonly :#{column}\n" unless options[:readonly].is_a? FalseClass

          code << "validates_presence_of :#{column}, :if=>lambda{|r| not r.#{column}.blank?}\n"

          code << "validates_uniqueness_of :#{column}\n"

          code << "before_validation(:on => :create) do\n"
          code << "  last = #{last}\n"
          code << "  self.#{column} = (last.nil? ? #{options[:start].inspect} : last.#{column}.blank? ? #{options[:start].inspect} : last.#{column}.succ)\n"
          code << "  return true\n"
          code << "end\n"

          code << "after_validation(:on => :create) do\n"
          code << "  if sequence = Sequence.of('#{sequence}')\n"
          code << "    self.#{column} = sequence.next_value\n"
          code << "  else\n"
          code << "    last = #{last}\n"
          code << "    self.#{column} = (last.nil? ? #{options[:start].inspect} : last.#{column}.blank? ? #{options[:start].inspect} : last.#{column}.succ)\n"
          code << "  end\n"
          code << "  return true\n"
          code << "end\n"
          # puts code
          class_eval code
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Numbered)
