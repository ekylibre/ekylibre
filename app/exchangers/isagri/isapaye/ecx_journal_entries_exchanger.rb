module Isagri
  module Isapaye
    # Exchanger to import COFTW.isa files from IsaCompta software
    class EcxJournalEntriesExchanger < ActiveExchanger::Base
      category :accountancy
      vendor :isagri

      def check
        valid = true
        begin
          SVF::Isapaye.parse(file)
        rescue SVF::InvalidSyntax
          valid = false
        end
        isapaye = SVF::Isapaye.parse(file)
        isapaye.folder.entries.each do |entry|
          if entry.printed_on.blank?
            w.error "Errors on printed_on (#{entry.printed_on})".red
            valid = false
          end

          fy_start = FinancialYear.at(entry.printed_on)
          unless fy_start
            w.error "FinancialYear does not exist for #{entry.label}".red
            valid = false
          end
          entry.lines.each do |line|
            if line.account.blank? || line.label.blank? || line.debit.blank? || line.credit.blank?
              w.error "One line on #{entry.label} is invalid".red
              valid = false
            end
          end
        end
        valid
      end

      def import

        isapaye = SVF::Isapaye.parse(file)
        w.count = isapaye.folder.entries.count

        # find or create a unique journal for ISAPAYE
        journal = find_or_create_journal('ISAP', 'Import ISAPAYE', 'various')

        entries = {}

        isapaye.folder.entries.each do |entry|
          number = entry.printed_on.to_formatted_s(:number)

          entries[number] = {
            printed_on: entry.printed_on,
            journal: journal,
            number: number,
            currency: journal.currency,
            provider: provider_value,
            items_attributes: {}
          }

          entry.lines.each do |line|
            account = find_or_create_account(line.account, line.label)
            # create entry item attributes
            id = (entries[number][:items_attributes].keys.max || 0) + 1
            entries[number][:items_attributes][id] = {
              real_debit: line.debit.to_f,
              real_credit: line.credit.to_f,
              account: account,
              name: line.label
            }
          end
          w.check_point
        end
        # create entries
        w.reset!(entries.keys.size)
        # create entry
        entries.values.each do |entry|
          j = JournalEntry.create!(entry)
          w.info "JE created: #{j.number} | #{j.printed_on}".inspect.yellow
          w.check_point
        end
        true
      end

      private

        def account_normalizer
          @account_normalier ||= Accountancy::AccountNumberNormalizer.build
        end

        # @param [String] jou_code
        # @param [String] jou_name
        # @param [Symbol] jou_nature
        # @return [Journal]
        def find_or_create_journal(jou_code, jou_name, jou_nature)
          Maybe(find_journal_by_provider(jou_code))
            .recover { create_journal(jou_code, jou_name, jou_nature) }
            .or_raise
        end

        # @param [String] code
        # @param [String] name
        # @param [Symbol] nature
        # @return [Journal]
        def create_journal(code, name, nature)
          Journal.create!(name: name, code: code, nature: nature, provider: provider_value(journal_code: code))
        end

        # @param [String]
        # @return [Journal, nil]
        def find_journal_by_provider(code)
          unwrap_one('journal') do
            Journal.of_provider_name(self.class.vendor, provider_name)
                   .of_provider_data(:journal_code, code)
          end
        end

        # @param [String] acc_number
        # @param [String] acc_name
        # @return [Account]
        def find_or_create_account(acc_number, acc_name)
          Maybe(find_account_by_provider(acc_number))
            .recover { find_or_create_account_by_number(acc_number, acc_name) }
            .or_raise
        end

        # @param [String] account_number
        # @return [Account, nil]
        def find_account_by_provider(account_number)
          unwrap_one('account') do
            Account.of_provider_name(self.class.vendor, provider_name)
                   .of_provider_data(:account_number, account_number)
          end
        end

        # @param [String] acc_number
        # @param [String] acc_name
        # @return [Account]
        def find_or_create_account_by_number(acc_number, acc_name)
          normalized = account_normalizer.normalize!(acc_number)

          Maybe(Account.find_by(number: normalized))
            .recover { create_account(acc_number, normalized, acc_name) }
            .or_raise
        end

        # @param [String] acc_number
        # @param [String] acc_name
        # @return [Account]
        def create_account(acc_number, acc_number_normalized, acc_name)
          attrs = {
            name: acc_name,
            number: acc_number_normalized,
            provider: provider_value(account_number: acc_number)
          }
          Account.create!(attrs)
        end

      protected

        def unwrap_one(name, exact: false, &block)
          results = block.call
          size = results.size

          if size > 1
            raise UniqueResultExpectedError.new("Expected only one #{name}, got #{size}")
          elsif exact && size == 0
            raise UniqueResultExpectedError.new("Expected only one #{name}, got none")
          else
            results.first
          end
        end

        # @return [Import]
        def import_resource
          @import_resource ||= Import.find(options[:import_id])
        end

        def provider_value(**data)
          { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: data }
        end

        def provider_name
          :isapaye_journal_entries
        end
    end
  end
end
