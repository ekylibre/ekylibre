module Ekylibre
  module Record
    class Scope < Struct.new(:name, :arity)
    end

    class Base < ActiveRecord::Base
      self.abstract_class = true

      cattr_accessor :scopes do
        []
      end

      # Replaces old module: ActiveRecord::Acts::Tree
      # include ActsAsTree

      # Permits to use enumerize in all models
      extend Enumerize

      # Make all models stampables
      stampable

      before_update :check_if_updateable?
      before_destroy :check_if_destroyable?

      def check_if_updateable?
        true
        # raise RecordNotUpdateable unless self.updateable?
      end

      def check_if_destroyable?
        unless destroyable?
          raise RecordNotDestroyable, "#{self.class.name} ID=#{id} is not destroyable"
        end
      end

      def destroyable?
        true
      end

      def updateable?
        true
      end

      def editable?
        updateable?
      end

      def self.customizable?
        respond_to?(:custom_fields)
      end

      def customizable?
        self.class.customizable?
      end

      def customized?
        customizable? && self.class.custom_fields.any?
      end

      def human_attribute_name(*args)
        self.class.human_attribute_name(*args)
      end

      # Returns a relation for all other records
      def others
        self.class.where.not(id: (id || -1))
      end

      # Returns a relation for the old record in DB
      def old_record
        return nil if new_record?
        self.class.find_by(id: id)
      end

      def already_updated?
        self.class.where(id: id, lock_version: lock_version).empty?
      end

      @@readonly_counter = 0

      class << self
        def has_picture(options = {})
          default_options = {
            url: '/backend/:class/:id/picture/:style',
            path: ':tenant/:class/:attachment/:id_partition/:style.:extension',
            styles: {
              thumb: ['64x64>', :jpg],
              identity: ['180x180#', :jpg]
            },
            convert_options: {
              thumb:    '-background white -gravity center -extent 64x64',
              identity: '-background white -gravity center -extent 180x180'
            }
          }
          has_attached_file :picture, default_options.deep_merge(options)
        end

        def columns_definition
          Ekylibre::Schema.tables[table_name] || {}.with_indifferent_access
        end

        def simple_scopes
          scopes.select { |x| x.arity.zero? }
        end

        def complex_scopes
          scopes.select { |x| !x.arity.zero? }
        end

        # Permits to consider something and something_id like the same
        def scope_with_registration(name, body, &block)
          # Check body.is_a?(Relation) to prevent the relation actually being
          # loaded by respond_to?
          if body.is_a?(::ActiveRecord::Relation) || !body.respond_to?(:call)
            ActiveSupport::Deprecation.warn('Using #scope without passing a callable object is deprecated. For ' \
                                            "example `scope :red, where(color: 'red')` should be changed to " \
                                            "`scope :red, -> { where(color: 'red') }`. There are numerous gotchas " \
                                            'in the former usage and it makes the implementation more complicated ' \
                                            'and buggy. (If you prefer, you can just define a class method named ' \
                                            "`self.red`.)\n" + caller.join("\n"))
          end
          arity = begin
                    body.arity
                  rescue
                    0
                  end
          scopes << Scope.new(name.to_sym, arity)
          scope_without_registration(name, body, &block)
        end
        alias_method_chain :scope, :registration

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
          Rails.logger.warn 'Cannot support Proc scope' unless scope.nil?
          column = ["#{name}_tid".to_sym, "#{name}_name".to_sym, name].detect { |c| columns_definition[c] }
          options[:foreign_key] ||= column
          reflection = Nomen::Reflection.new(self, name, options)
          @nomenclature_reflections ||= {}.with_indifferent_access
          @nomenclature_reflections[reflection.name] = reflection
          enumerize reflection.foreign_key, in: reflection.all(reflection.scope),
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
            self[reflection.foreign_key] = value.is_a?(Nomen::Item) ? value.name : value
          end

          # Define a default scope "of_<name>"
          scope "of_#{name}".to_sym, proc { |*items|
            where(reflection.foreign_key => items.map { |i| reflection.klass.all(i) }.flatten.uniq)
          }

          define_method "of_#{name}?" do |item_or_name|
            item = item_or_name.is_a?(Nomen::Item) ? item_or_name : reflection.klass.find(item_or_name)
            self[reflection.foreign_key].present? && item >= self[reflection.foreign_key]
          end
        end

        # Permits to consider something and something_id like the same
        def human_attribute_name_with_id(attribute, options = {})
          human_attribute_name_without_id(attribute.to_s.gsub(/_id\z/, ''), options)
        end
        alias_method_chain :human_attribute_name, :id

        # Permits to add conditions on attr_readonly
        def attr_readonly_with_conditions(*args)
          options = args.extract_options!
          return attr_readonly_without_conditions(*args) unless options[:if]
          if options[:if].is_a?(Symbol)
            method_name = options[:if]
          else
            method_name = "readonly_#{@@readonly_counter += 1}?"
            send(:define_method, method_name, options[:if])
          end
          code = ''
          code << "before_update do\n"
          code << "  if self.#{method_name}\n"
          code << "    old = #{name}.find(self.id)\n"
          args.each do |attribute|
            code << "  self['#{attribute}'] = old['#{attribute}']\n"
          end
          code << "  end\n"
          code << "end\n"
          class_eval code
        end
        alias_method_chain :attr_readonly, :conditions
      end
    end
  end
end
