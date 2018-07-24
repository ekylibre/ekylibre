module Ekylibre
  module Record
    module Acts #:nodoc:
      module Numbered #:nodoc:
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def sequence_manager
            @sequence_manager || superclass.sequence_manager
          end

          def enumeration_condition
            @enumeration_condition
          end

          # Use preference to select preferred sequence to attribute number
          # in column
          def acts_as_numbered(*args)
            options = args.extract_options!
            numbered_column = args.shift || :number

            options = { start: '00000001' }.merge(options)
                                           .merge(usage: options[:usage] || main_class.name.tableize)
                                           .merge(column: numbered_column)

            ensure_validity!(options[:column], options[:usage])

            @sequence_manager = SequenceManager.new(main_class, options)
            delegate :sequence_manager, to: :class

            @enumeration_condition = options[:unless]
            delegate :enumeration_condition, to: :class

            attr_readonly :"#{options[:column]}" if options[:readonly]

            validates :"#{options[:column]}", presence: true

            if enumeration_condition.blank?
              validates :"#{options[:column]}", uniqueness: true
            end

            define_sequence_methods(options[:column])
          end

          private

          def define_sequence_methods(column)
            define_next(column)
            define_load_reliable(column)
            define_load_predictable(column)
            define_unique_predictable(column)
          end

          def ensure_validity!(column, usage)
            raise "Usage #{usage} must be defined in Sequence usages" unless Sequence.usage.values.include?(usage)
            return true if columns_definition[column]
            Rails.logger.fatal "Method #{column.inspect} must be an existent column of the table #{table_name}"
          end

          def main_class
            klass = self
            klass = superclass until [Ekylibre::Record::Base, ActiveRecord::Base].include? klass.superclass
            klass
          end

          def define_next(column)
            define_method :"next_#{column}" do
              sequence_manager.next_number
            end
          end

          def define_unique_predictable(column)
            define_method :"unique_predictable_#{column}" do
              sequence_manager.unique_predictable
            end
          end

          def define_load_predictable(column)
            before_validation :"load_unique_predictable_#{column}", on: :create

            define_method :"load_unique_predictable_#{column}" do
              if enumeration_condition.present?
                unless send(self.class.enumeration_condition)
                  sequence_manager.load_predictable_into self
                end
              else
                sequence_manager.load_predictable_into self
              end
            end
          end

          def define_load_reliable(column)
            after_validation :"load_unique_reliable_#{column}", on: :create

            define_method :"load_unique_reliable_#{column}" do
              if enumeration_condition.present?
                unless send(self.class.enumeration_condition)
                  sequence_manager.load_reliable_into self
                end
              else
                sequence_manager.load_predictable_into self
              end
            end
          end
        end
      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Numbered)
