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
          code  = ''

          # `Module#name` rend une chaîne gelée depuis Ruby 2.7 : le `<<` qui
          # suit lèverait FrozenError. Le `+` unaire en rend une copie mutable.
          scope = +table_name.classify.constantize.name
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
            # `:on` n'a jamais été une option de `before_save` — elle n'existe que
            # pour `before_validation` et les rappels de commit. Rails 5
            # l'ignorait en silence, si bien que les deux méthodes s'exécutaient
            # de toute façon à la création comme à la mise à jour ; Rails 6 lève
            # `Unknown key: :on`. L'option est retirée sans rien changer au
            # comportement effectif.
            #
            # Reste une question de fond, laissée en l'état faute de mandat :
            # les noms disent l'intention d'origine — `_if_first` à la création,
            # `_if_alone` à la mise à jour — et cette séparation n'a jamais eu
            # lieu. La rétablir changerait le comportement de neuf modèles.
            code << "before_save(:set_#{column}_if_first)\n"
            code << "before_save(:set_#{column}_if_alone)\n"
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

            pode = "self.update!(#{column}: true)\n"
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

            pode = "self.#{column} = true unless #{scope}.where(#{column}: true).any?\n"
            code << "def set_#{column}_if_first\n"
            if options[:if]
              code << "  if self.#{options[:if]}\n"
              code << pode.dig(2)
              code << "  end\n"
            else
              code << pode.dig
            end
            code << "end\n"

            pode << "self.#{column} = true unless #{scope}.where(#{column}: true).where.not(id: self.id).any?\n"
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
            pode << "  #{scope}.where(#{column}: true).where.not(id: self.id).update_all(#{column}: false)\n"
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

          class_eval code
        end
      end
    end
  end
end
