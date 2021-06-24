module Ekylibre
  module Record
    module Bookkeep
      class Base
        attr_reader :resource, :action, :draft

        cattr_reader :id
        @@id = '0'

        def self.next_id
          @@id.succ!
          @@id
        end

        def initialize(resource, action, draft)
          raise ArgumentError.new("Unvalid action #{action.inspect} (#{Ekylibre::Record::Bookkeep::ACTIONS.to_sentence} are accepted)") unless Ekylibre::Record::Bookkeep::ACTIONS.include? action

          @resource = resource
          @action = action
          @draft = draft
        end

        def journal_entry(journal, options = {}, &block)
          if (options.keys & %i[if unless]).size > 1
            raise ArgumentError.new('Options :if and :unless are incompatible.')
          end
          if options.key? :list
            raise ArgumentError.new('Option :list is not supported anymore.')
          end

          raise ArgumentError.new('Block is missing') unless block_given?

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
            raise ArgumentError.new("Date of journal_entry (printed_on) must be given. Date expected, got #{attributes[:printed_on].class.name} (#{attributes[:printed_on].inspect})")
          end

          if condition
            unless journal.is_a? Journal
              raise ArgumentError.new("Unknown journal: (#{journal.inspect})")
            end

            attributes[:journal_id] = journal.id
          end

          ApplicationRecord.transaction do
            journal_entry = JournalEntry.find_by(id: @resource.send(column))
            list = record(&block)

            if journal_entry && condition && (!journal_entry.draft? || list.empty? ||
              attributes[:journal_id] != journal_entry.journal_id ||
              @action == :destroy)
              journal_entry.cancel
              journal_entry = nil
            end

            # Add journal items
            if condition && list.any? && @action != :destroy
              attributes[:items] = []

              list.each do |cmd|
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
              attributes[:real_currency_rate] = 1 # FIXME: we should have a real currency conversion system
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
    end
  end
end
