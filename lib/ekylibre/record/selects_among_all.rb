module Ekylibre
  module Record
    module SelectsAmongAll #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Manage
        def selects_among_all(*columns)
          options = columns.extract_options!

          columns = [:by_default] if columns.empty?
          code  = []

          scope = [table_name.classify.constantize.name] # "self.class"
          scope << ".#{options[:subset]}" if options[:subset]
          scope_columns = []
          if s = options[:scope]
            s = [s] if s.is_a?(Symbol)
            unless s.is_a?(Symbol) || s.is_a?(Array)
              raise ArgumentError.new('Scope must be given as a Symbol or an Array of Symbol')
            end

            scope << '.where(' + s.collect do |c|
              scope_columns << c.to_sym
              "#{c}: self.#{c}"
            end.join(', ') + ')'
          end

          columns.each do |column|
            code << "before_save(:set_#{column}_if_first, on: :create)\n"
            code << "before_save(:set_#{column}_if_alone, on: :update)\n"
            code << "after_save(:ensure_#{column}_uniqueness)\n"

            pode = "self.update_column(:#{column}, true)\n"
            code << "def set_#{column}\n"
            if options[:if]
              code << "  if self.#{options[:if]}\n"
              code << pode.dig(2)
              code << "  else\n"
              code << "    return false\n"
              code << "  end\n"
            else
              code << pode.dig
            end
            code << "end\n"

            pode = "self.update_attributes!(#{column}: true)\n"
            code << "def set_#{column}!\n"
            if options[:if]
              code << "  if self.#{options[:if]}\n"
              code << pode.dig(2)
              code << "  else\n"
              code << "    fail 'Cannot selects #{column}'\n"
              code << "  end\n"
            else
              code << pode.dig
            end
            code << "end\n"

            pode = "self.#{column} = true unless #{scope.join}.where(#{column}: true).any?\n"
            code << "def set_#{column}_if_first\n"
            if options[:if]
              code << "  if self.#{options[:if]}\n"
              code << pode.dig(2)
              code << "  end\n"
            else
              code << pode.dig
            end
            code << "end\n"

            pode << "self.#{column} = true unless #{scope.join}.where(#{column}: true).where.not(id: self.id).any?\n"
            code << "def set_#{column}_if_alone\n"
            if options[:if]
              code << "  if self.#{options[:if]}\n"
              code << pode.dig(2)
              code << "  end\n"
            else
              code << pode.dig
            end
            code << "end\n"

            pode = "if self.#{column}?\n"
            pode << "  #{scope.join}.where(#{column}: true).where.not(id: self.id).update_all(#{column}: false)\n"
            pode << "end\n"
            code << "def ensure_#{column}_uniqueness\n"
            if options[:if]
              code << "  if self.#{options[:if]}\n"
              code << pode.dig(2)
              code << "  end\n"
            else
              code << pode.dig
            end
            code << "end\n"

            code << "def self.#{column}(" + scope_columns.collect { |c| "#{c} = nil" }.join(', ') + ")\n"
            if scope_columns.any?
              code << '  if ' + scope_columns.collect { |c| "#{c}.nil?" }.join(' or ') + "\n"
              code << "    fail ArgumentError, '#{scope_columns.size} arguments expected: " + scope_columns.join(', ') + "'\n"
              code << "  end\n"
            end
            code << '  self.find_by(' + scope_columns.collect { |c| "#{c}: #{c}, " }.join + "#{column}: true)\n"
            code << "end\n"
          end

          class_eval code.join
        end
      end
    end
  end
end
