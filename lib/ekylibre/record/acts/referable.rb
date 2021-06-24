module Ekylibre
  module Record
    module Acts
      module Referable
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def nomenclature_reflections
            @nomenclature_reflections ||= {}.with_indifferent_access
            if superclass.respond_to?(:nomenclature_reflections)
              superclass.nomenclature_reflections.merge(@nomenclature_reflections)
            else
              @nomenclature_reflections
            end
          end

          # Link to nomenclature
          def refers_to(name, *args)
            options = args.extract_options!
            scope = args.shift
            Rails.logger.warn "Cannot support Proc scope in #{self.class.name}" unless scope.nil?
            column = ["#{name}_tid".to_sym, "#{name}_name".to_sym, name].detect { |c| columns_definition[c] }
            options[:foreign_key] ||= column
            reflection = Onoma::Reflection.new(self, name, options)
            @nomenclature_reflections ||= {}.with_indifferent_access
            @nomenclature_reflections[reflection.name] = reflection
            enumerize reflection.foreign_key, in: reflection.all(reflection.scope),
                      predicates: options[:predicates],
                      i18n_scope: ["nomenclatures.#{reflection.nomenclature}.items"]

            if reflection.foreign_key != reflection.name
              define_method name do
                reflection.klass.find(self[reflection.foreign_key])
              end
            else
              define_method "#{name}_name" do
                item = reflection.klass.find(self[reflection.foreign_key])
                item ? item.name : nil
              end
            end

            define_method "human_#{name}_name" do
              item = reflection.klass.find(self[reflection.foreign_key])
              item ? item.human_name : nil
            end

            define_method "#{name}=" do |value|
              self[reflection.foreign_key] = value.is_a?(Onoma::Item) ? value.name : value
            end

            # Define a default scope "of_<name>"
            scope("of_#{name}".to_sym, proc { |*items|
              where(reflection.foreign_key => items.map { |i| reflection.klass.all(i) }.flatten.uniq)
            })

            define_method "of_#{name}?" do |item_or_name|
              item = item_or_name.is_a?(Onoma::Item) ? item_or_name : reflection.klass.find(item_or_name)
              self[reflection.foreign_key].present? && item >= self[reflection.foreign_key]
            end
          end
        end
      end
    end
  end
end
