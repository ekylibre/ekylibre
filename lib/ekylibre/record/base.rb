module Ekylibre
  module Record
    class RecordInvalid < ActiveRecord::RecordNotSaved
    end

    class Scope < Struct.new(:name, :arity)
    end

    class Base < ActiveRecord::Base
      include ::ConditionalReadonly # TODO: move to ApplicationRecord
      prepend ::IdHumanizable
      include ::ScopeIntrospection # TODO: move to ApplicationRecord
      include Userstamp::Stamper
      include Userstamp::Stampable
      include HasInterval

      self.abstract_class = true

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

      def unsuppress
        yield
      rescue ActiveRecord::RecordInvalid => would_be_silently_dropped
        Rails.logger.info would_be_silently_dropped.inspect
        wont_be_dropped = Ekylibre::Record::RecordInvalid.new(would_be_silently_dropped.message,
                                                              would_be_silently_dropped.record)
        wont_be_dropped.set_backtrace(would_be_silently_dropped.backtrace)
        raise wont_be_dropped
      end

      def human_changed_attribute_value(change, state)
        att = change.attribute.gsub(/_id$/, '')
        value_retrievable = change.attribute.match(/_id$/) && respond_to?(att) && send(att).respond_to?('name')
        return change.send("human_#{state}_value") unless value_retrievable
        send(att).respond_to?('label') ? send(att).label : send(att).name
      end

      class << self
        attr_accessor :readonly_counter

        def has_picture(options = {})
          default_options = {
            url: '/backend/:class/:id/picture/:style',
            path: ':tenant/:class/:attachment/:id_partition/:style.:extension',
            styles: {
              thumb: ['64x64>', :jpg],
              identity: ['180x180#', :jpg],
              contact: ['720x720#', :jpg]
            },
            convert_options: {
              thumb:    '-background white -gravity center -extent 64x64',
              identity: '-background white -gravity center -extent 180x180',
              contact: '-background white -gravity center -extent 720x720'
            }
          }
          has_attached_file :picture, default_options.deep_merge(options)
        end

        def columns_definition
          Ekylibre::Schema.tables[table_name] || {}.with_indifferent_access
        end

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
          reflection = Nomen::Reflection.new(self, name, options)
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
      end
    end
  end
end
