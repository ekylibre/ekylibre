module Ekylibre
  module Record
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
              raise "Usage #{usage} must be defined in Sequence usages"
            end

            find_last = proc { main_class.where.not(column => nil).reorder("LENGTH(#{column}) DESC, #{column} DESC").first }

            attr_readonly :"#{column}" unless options[:readonly] == false

            validates :"#{column}", presence: true, uniqueness: true

            before_validation :"load_unique_predictable_#{column}", on: :create
            before_validation :"load_unique_reliable_#{column}", on: :create

            define_method :"next_#{column}" do
              sequence = Sequence.of(usage)
              return sequence.next_value if sequence
              last = find_last.call
              return options[:start] if last.nil? || last.blank?
              last.send(column).succ
            end

            define_method :"unique_predictable_#{column}" do
              last = find_last.call
              value = options[:start]
              value = last.send(column).succ unless last.nil? || last.blank?
              value = value.succ while main_class.find_by(column => value)
              value
            end

            define_method :"load_unique_predictable_#{column}" do
              return true if options[:force] == false && send(column).present?
              send(:"#{column}=", send(:"unique_predictable_#{column}"))
              true
            end

            define_method :"load_unique_reliable_#{column}" do
              return true if options[:force] == false && send(column)
              unless sequence = Sequence.of(usage)
                send(:"#{column}=", send(:"unique_predictable_#{column}"))
                return true
              end

              value = sequence.next_value!
              value = sequence.next_value! while main_class.find_by(column => value)
              send(:"#{column}=", value)
              true
            end
          end
        end
      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Numbered)
