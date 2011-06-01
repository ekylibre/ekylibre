module Ekylibre
  module BasicValidations
    module ActiveRecord
      module Base
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def self.extended(base)
            class << base
              alias_method_chain :allocate, :basic_validations
              alias_method_chain :new, :basic_validations
              alias_method_chain :inherited, :basic_validations
            end
          end

          def inherited_with_basic_validations(child)
            load_basic_validations unless self == ::ActiveRecord::Base
            inherited_without_basic_validations(child)
          end

          def basic_validations(options = {})
            column_names = []
            if options[:only]
              column_names = options[:only]
              @basic_validations_column_include = true
            elsif options[:except]
              column_names = options[:except]
              @basic_validations_column_include = false
            end

            @basic_validations_column_names = Array(column_names).map(&:to_s)
          end

          def allocate_with_basic_validations
            load_basic_validations
            allocate_without_basic_validations
          end

          def new_with_basic_validations(*args)
            load_basic_validations
            new_without_basic_validations(*args) { |*block_args| yield(*block_args) if block_given? }
          end

          protected

          def load_basic_validations
            # Don't bother if: it's already been loaded; the class is abstract; not a base class; or the table doesn't exist
            return if @basic_validations_loaded || self.abstract_class? || (self!=base_class) || name.blank? || !table_exists?
            @basic_validations_loaded = true
            load_column_validations
            load_association_validations
          end

          private
          
          def load_column_validations
            content_columns.each do |column|
              next unless validates?(column)

              name = column.name.to_sym

              # Data-type validation
              if column.type == :integer
                validates_numericality_of name, :allow_nil => true, :only_integer => true
              elsif column.number?
                validates_numericality_of name, :allow_nil => true
              elsif column.text? && column.limit
                validates_length_of name, :allow_nil => true, :maximum => column.limit
              end

              unless column.null
                if column.type == :boolean
                  validates_inclusion_of name, :in => [true, false], :message => "activerecord.errors.messages.blank".to_sym
                else
                  validates_presence_of name
                end
              end
            end
          end
          
          def load_association_validations
            columns = columns_hash
            reflect_on_all_associations(:belongs_to).each do |association|
              return if association.active_record.name=="ActiveRecord::Base"
              column = columns[Rails.version.match(/^3\./) ? association.foreign_key.to_s : association.primary_key_name.to_s]
              raise Exception.new("Problem in #{association.active_record.name} at '#{association.macro} :#{association.name}'\n#{association.inspect}\n#{columns.collect{|k,v| k}.inspect}") if column.nil?
              next unless validates?(column)

              # NOT NULL constraints
              module_eval("validates_presence_of :#{column.name}, :if => lambda { |record| record.#{association.name}.nil? }") unless column.null

            end
          end

          def validates?(column)
            column.name !~ /^(((created|updated)_(at|on))|position)$/ &&
              (@basic_validations_column_names.nil? || @basic_validations_column_names.include?(column.name) == @basic_validations_column_include)
          end

        end
      end
    end
  end
end


