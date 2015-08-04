module Ekylibre::Record
  module Acts #:nodoc:
    module Numbered #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Use preference to select preferred sequence to attribute number
        # in column
        def acts_as_numbered(*args)
          options = args[-1].is_a?(Hash) ? args.delete_at(-1) : {}
          column = args.shift || :number

          unless columns_definition[column]
            Rails.logger.fatal "Method #{column.inspect} must be an existent column of the table #{table_name}"
          end

          options = { start: '00000001' }.merge(options)

          main_class = self
          while main_class.superclass != Ekylibre::Record::Base && main_class.superclass != ActiveRecord::Base
            main_class = superclass
          end
          class_name = main_class.name

          usage = options[:usage] || class_name.tableize
          unless Sequence.usage.values.include?(usage)
            fail "Usage #{usage} must be defined in Sequence usages"
          end

          last  = "#{class_name}.where('#{column} IS NOT NULL').reorder('LENGTH(#{column}) DESC, #{column} DESC').first"

          code  = ''

          code << "attr_readonly :#{column}\n" unless options[:readonly].is_a? FalseClass

          code << "validates :#{column}, presence: true, uniqueness: true\n"

          code << "before_validation(:load_unique_predictable_#{column}, on: :create)\n"
          code << "after_validation(:load_unique_reliable_#{column}, on: :create)\n"

          code << "def load_unique_predictable_#{column}\n"
          code << "  unless self.#{column}\n" if options[:force].is_a?(FalseClass)
          code << "    last = #{last}\n"
          code << "    self.#{column} = (last.nil? ? #{options[:start].inspect} : last.#{column}.blank? ? #{options[:start].inspect} : last.#{column}.succ)\n"
          code << "    while #{class_name}.find_by(#{column}: self.#{column}) do\n"
          code << "      self.#{column}.succ!\n"
          code << "    end\n"
          code << "  end\n" if options[:force].is_a?(FalseClass)
          code << "  return true\n"
          code << "end\n"

          code << "def load_unique_reliable_#{column}\n"
          code << "  unless self.#{column}\n" if options[:force].is_a?(FalseClass)
          code << "    if sequence = Sequence.of('#{usage}')\n"
          code << "      self.#{column} = sequence.next_value\n"
          code << "      while #{class_name}.find_by(#{column}: self.#{column}) do\n"
          code << "        self.#{column} = sequence.next_value\n"
          code << "      end\n"
          code << "    else\n"
          code << "      last = #{last}\n"
          code << "      self.#{column} = (last.nil? ? #{options[:start].inspect} : last.#{column}.blank? ? #{options[:start].inspect} : last.#{column}.succ)\n"
          code << "      while #{class_name}.find_by(#{column}: self.#{column}) do\n"
          code << "        self.#{column}.succ!\n"
          code << "      end\n"
          code << "    end\n"
          code << "  end\n" if options[:force].is_a?(FalseClass)
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
