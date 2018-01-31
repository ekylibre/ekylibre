module Ekylibre
  module Record #:nodoc:
    module Bookkeep
      def self.actions
        %i[create update destroy]
      end

      class EntryRecorder
        attr_reader :list

        def initialize
          @list = []
        end

        def add_debit(*args)
          @list << [:add_debit, *args]
        end

        def add_credit(*args)
          @list << [:add_credit, *args]
        end
      end

      class Base
        attr_reader :resource, :action, :draft

        cattr_reader :id
        @@id = '0'

        def self.next_id
          @@id.succ!
          @@id
        end

        def initialize(resource, action, draft)
          raise ArgumentError, "Unvalid action #{action.inspect} (#{Ekylibre::Record::Bookkeep.actions.to_sentence} are accepted)" unless Ekylibre::Record::Bookkeep.actions.include? action
          @resource = resource
          @action = action
          @draft = draft
        end

        def journal_entry(journal, options = {}, &block)
          if (options.keys & %i[if unless]).size > 1
            raise ArgumentError, 'Options :if and :unless are incompatible.'
          end
          if options.key? :list
            raise ArgumentError, 'Option :list is not supported anymore.'
          end
          raise ArgumentError, 'Block is missing' unless block_given?
          condition = (options.key?(:if) ? options.delete(:if) : !options.delete(:unless))
          prism = options.delete(:as)
          column = options.delete(:column)
          if prism.blank?
            prism ||= resource.class.name.underscore
            column ||= :journal_entry_id
          else
            column ||= "#{prism}_journal_entry_id".to_sym
          end

          attributes = options
          attributes[:resource] ||= @resource
          attributes[:resource_prism] ||= prism
          # attributes[:state]      ||= @state
          attributes[:printed_on] ||= @resource.created_at.to_date if @resource.respond_to? :created_at
          unless attributes[:printed_on].is_a?(Date)
            raise ArgumentError, "Date of journal_entry (printed_on) must be given. Date expected, got #{attributes[:printed_on].class.name} (#{attributes[:printed_on].inspect})"
          end
          if condition
            unless journal.is_a? Journal
              raise ArgumentError, "Unknown journal: (#{journal.inspect})"
            end
            attributes[:journal_id] = journal.id
          end

          Ekylibre::Record::Base.transaction do
            journal_entry = JournalEntry.find_by(id: @resource.send(column))
            list = record(&block)

            if journal_entry && (!journal_entry.draft? || list.empty? ||
                                 attributes[:journal_id] != journal_entry.journal_id ||
                                 @action == :destroy)
              journal_entry.cancel
              journal_entry = nil
            end

            # Add journal items
            if condition && list.any? && @action != :destroy
              attributes[:items] = []

              for cmd in list
                direction = cmd.shift
                unless %i[add_debit add_credit].include?(direction)
                  raise 'Can accept only add_debit and add_credit commands'
                end
                cmd[3] ||= {}
                cmd[3][:credit] = true if direction == :add_credit
                attributes[:items] << JournalEntryItem.new_for(*cmd)
              end

              attributes[:financial_year] = FinancialYear.at(attributes[:printed_on])
              attributes[:currency] = attributes[:financial_year].currency if attributes[:financial_year]
              attributes[:real_currency] = Journal.find(attributes[:journal_id]).currency
              journal_entry ||= JournalEntry.new
              journal_entry.attributes = attributes
              journal_entry.save!
              journal_entry.confirm unless @draft
            end

            # Set accounted columns
            if @resource.class.exists?(@resource.id)
              @resource.update_columns(
                accounted_at: Time.zone.now,
                column => (journal_entry ? journal_entry.id : nil)
              )
            end
          end
        end

        def record
          recorder = EntryRecorder.new
          yield(recorder)
          recorder.list
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def bookkeep(options = {}, &block)
          raise ArgumentError, 'No given block' unless block_given?
          raise ArgumentError, "Wrong number of arguments (#{block.arity} for 1)" unless block.arity == 1
          configuration = { on: Ekylibre::Record::Bookkeep.actions, column: :accounted_at, method_name: __method__ }
          configuration.update(options) if options.is_a?(Hash)
          configuration[:column] = configuration[:column].to_s
          method_name = configuration[:method_name].to_s
          core_method_name ||= "_#{method_name}_#{Ekylibre::Record::Bookkeep::Base.next_id}"

          unless columns_definition[configuration[:column]]
            Rails.logger.fatal "#{configuration[:column]} is needed for #{name}::bookkeep"
            # raise StandardError, "#{configuration[:column]} is needed for #{self.name}::bookkeep"
          end

          include Ekylibre::Record::Bookkeep::InstanceMethods

          define_method method_name do |action = :create, draft = nil|
            draft = ::Preference[:bookkeep_in_draft] if draft.nil?
            send(core_method_name, Ekylibre::Record::Bookkeep::Base.new(self, action, draft))
            self.class.where(id: id).update_all(configuration[:column] => Time.zone.now)
          end

          configuration[:on] = [configuration[:on]].flatten
          Ekylibre::Record::Bookkeep.actions.each do |action|
            next unless configuration[:on].include? action
            send("after_#{action}") do
              if ::Preference[:bookkeep_automatically]
                send(method_name, action, ::Preference[:bookkeep_in_draft])
              end
              true
            end
          end

          send(:define_method, core_method_name, &block)
        end
      end

      module InstanceMethods
        def accounted?
          !accounted_at.nil?
        end
      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Bookkeep)
