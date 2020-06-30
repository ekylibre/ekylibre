# frozen_string_literal: true
module Sage
  module ISeven
    class JournalEntriesExchanger < ActiveExchanger::Base
      JOURNAL_CODE_CLOSING = "SAGC"
      JOURNAL_CODE_FORWARD = "SAGF"

      # @type [Hash{String => Symbol}]
      DEFAULT_JOURNAL_NATURES = {
        'A' => :purchases,
        'V' => :sales,
        'T' => :bank,
        'D' => :various
      }.freeze

      class SageFileInformation
        class << self
          def read_from(doc, **options)
            period_started_on = doc.at_css('INFORMATION').attribute('PERIODEDEBUTN').value
            period_stopped_on = doc.at_css('INFORMATION').attribute('PERIODEFINN').value
            data_exported_on = doc.at_css('INFORMATION').attribute('DATECREATION').value
            version_information = doc.at_css('INFORMATION').attribute('VERSIONECX').value + ' - ' + doc.at_css('INFORMATION').attribute('VERSIONEMETTEUR').value

            new(period_started_on, period_stopped_on, data_exported_on, version_information, doc, options)
          end

          def load_from(file, **options)
            source = File.read(file)
            detection = CharlockHolmes::EncodingDetector.detect(source)

            doc = Nokogiri.XML(source, nil, detection[:encoding], &:noblanks)
            SageFileInformation.read_from(doc, options)
          end
        end

        attr_reader :period_started_on, :period_stopped_on, :data_exported_on, :version_information, :doc

        def initialize(period_started_on, period_stopped_on, data_exported_on, version_information, doc, **options)
          @period_started_on = period_started_on.to_date
          @period_stopped_on = period_stopped_on.to_date
          @data_exported_on = data_exported_on.to_date
          @version_information = version_information
          @doc = doc
        end
      end

      # @return [Boolean]
      def check
        valid = true
        if financial_year.nil?
          valid = false
          w.error "The financial year is needed for #{file_info.period_stopped_on}"
        end
        valid
      end

      def import
        accounts = retrieve_account(file_info.doc)

        accounts
          .select { |_k, account| account.auxiliary? }
          .each do |sage_number, entity_account|
          find_or_create_entity(file_info.period_started_on, entity_account, sage_number)
        end

        entries = entries_items(file_info.doc, financial_year)
        w.count = entries.count
        entries.each do |_key, entry|
          JournalEntry.create!(entry)
          w.check_point
        end
      rescue Accountancy::AccountNumberNormalizer::NormalizationError
        raise StandardError, tl(:errors, :incorrect_account_number_length)
      end

      private

      # @return [Accountancy::AccountNumberNormalizer]
      def number_normalizer
        @number_normalizer ||= Accountancy::AccountNumberNormalizer.build
      end

      # @return [SageFileInformation]
      def file_info
        @file_info ||= SageFileInformation.load_from(file, options)
      end

      # @return [FinancialYear, nil]
      def financial_year
        @financial_year ||= FinancialYear.find_by('stopped_on = ?', file_info.period_stopped_on)
      end

      # Create or update account chart with data in file
      # @param [] doc
      # @return [Hash{String => Account}]
      def retrieve_account(doc)
        accounts = {}
        # check account length
        # find or create account
        pc = doc.at_css('PC')
        acc_number_length = pc.css('COMPTE').first.attribute('COMPTE').value.length

        pc.css('COMPTE').each do |account|
          acc_number = account.attribute('COMPTE').value
          acc_name = account.attribute('NOM').value
          # Skip number with radical class only like 7000000 or 40000000
          next if acc_number.strip =~ /\A[1-9]0*\z/

          accounts[acc_number] = find_or_create_account(acc_number, acc_name)
        end

        accounts
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
          Account.of_provider_name(provider_vendor, provider_name)
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

        if acc_number.start_with?(client_account_radix, supplier_account_radix)
          aux_number = acc_number[client_account_radix.length..-1]

          if aux_number.match(/\A0*\z/).present?
            raise StandardError, tl(:errors, :radical_class_number_unauthorized, number: acc_number)
          end

          attrs = attrs.merge(
            centralizing_account_name: acc_number.start_with?(client_account_radix) ? 'clients' : 'suppliers',
            auxiliary_number: aux_number,
            nature: 'auxiliary'
          )
        end

        Account.create!(attrs)
      end

      # @return [String]
      def client_account_radix
        @client_account_radix ||= Preference.value(:client_account_radix).presence || '411'
      end

      # @return [String]
      def supplier_account_radix
        @supplier_account_radix ||= Preference.value(:supplier_account_radix).presence || '401'
      end

      # @param [Date] period_started_on
      # @param [Account] acc
      # @return [Entity]
      def find_or_create_entity(period_started_on, acc, sage_account_number)
        entity = Maybe(find_entity_by_provider(sage_account_number))
                   .recover { find_entity_by_account(acc) }
                   .recover { create_entity(period_started_on, acc, sage_account_number) }
                   .or_raise

        if entity.first_met_at.nil? || (period_started_on && period_started_on < entity.first_met_at.to_date)
          entity.update!(first_met_at: period_started_on.to_datetime)
        end

        entity
      end

      # @param [String] sage_account_number
      # @return [Entity, nil]
      def find_entity_by_provider(sage_account_number)
        unwrap_one('entity') do
          Entity.of_provider_name(provider_vendor, provider_name)
                .of_provider_data(:account_number, sage_account_number)
        end
      end

      # @param [Account] account
      # @return [Entity, nil]
      def find_entity_by_account(account)
        unwrap_one('entity') do
          if account.centralizing_account_name == "clients"
            Entity.where(client_account: account)
          elsif account.centralizing_account_name == "suppliers"
            Entity.where(supplier_account: account)
          else
            raise StandardError, tl(:errors, :unreachable_code)
          end
        end
      end

      # @param [Date] period_started_on
      # @param [Account] account
      # @param [String] sage_account_number
      # @return [Entity]
      def create_entity(period_started_on, account, sage_account_number)
        last_name = account.name.mb_chars.capitalize
        attrs = {
          last_name: last_name,
          nature: 'organization',
          first_met_at: period_started_on.to_datetime,
          provider: provider_value(account_number: sage_account_number)
        }
        if account.centralizing_account_name == "clients"
          attrs = {
            **attrs,
            client: true,
            client_account_id: account.id
          }
        elsif account.centralizing_account_name == "suppliers"
          attrs = {
            **attrs,
            supplier: true,
            supplier_account_id: account.id
          }
        else
          raise StandardError, tl(:errors, :unreachable_code)
        end

        Entity.create!(attrs)
      end

      # @param [String] sage_nature
      # @return [Boolean]
      def is_bank?(sage_nature)
        sage_nature == 'T'
      end

      # @param [Date] printed_on
      # @param [Date] stopped_on
      # @param [String] state
      # @return [Boolean]
      def is_closing_entry?(printed_on, stopped_on, state)
        printed_on.day == stopped_on.day && printed_on.month == stopped_on.month && state == '8'
      end

      # @param [Date] printed_on
      # @param [Date] started_on
      # @param [String] state
      # @return [Boolean]
      def is_forward_entry?(printed_on, started_on, state)
        printed_on.day == started_on.day && printed_on.month == started_on.month && state == '8'
      end

      # @param [] doc
      # @param [FinancialYear] fy
      # @return [Hash{String} => Hash}]
      def entries_items(doc, fy)
        entries = {}

        doc.css('JOURNAL').each do |sage_journal|
          # get attributes in file ## <JOURNAL> n occurences
          jou_code = sage_journal.attribute('CODE').value
          jou_name = sage_journal.attribute('NOM').value
          jou_nature = sage_journal.attribute('TYPEJOURNAL').value
          nature = DEFAULT_JOURNAL_NATURES[jou_nature]

          journal = find_or_create_journal(jou_code, jou_name, nature)

          find_or_create_cash(sage_journal, journal) if is_bank?(jou_nature)

          sage_journal.css('PIECE').each_with_index do |sage_journal_entry, index|
            printed_on = sage_journal_entry.attribute('DATEECR').value.to_date
            state = sage_journal_entry.attribute('ETAT').value
            line_number = index + 1
            number = jou_code + '_' + printed_on.to_s + '_' + line_number.to_s
            # change journal in case of result journal entry (31/12/AAAA and ETAT = 8)
            # Sate == 8 ==> Ecriture de generation de résultat si générées à la date de cloture
            c_journal = if is_closing_entry?(printed_on, fy.stopped_on, state)
                          find_or_create_journal(JOURNAL_CODE_CLOSING, tl(:journals, :closing), :closure)
                          #find_or_create_default_result_journal()
                        elsif is_forward_entry?(printed_on, fy.started_on, state)
                          find_or_create_journal(JOURNAL_CODE_FORWARD, tl(:journals, :forward), :forward)
                        else
                          journal
                        end

            attributes = sage_journal_entry.css('LIGNE').map do |sage_journal_entry_item|
              sjei_label = sage_journal_entry_item.attribute('LIBMANU').value
              sjei_amount = sage_journal_entry_item.attribute('MONTANTREF').value
              sjei_direction = sage_journal_entry_item.attribute('SENS').value # 1 = D / -1 = C

              account_number = sage_journal_entry_item.attribute('COMPTE').value
              sjei_account = find_or_create_account(account_number, sjei_label)

              {
                real_debit: (sjei_direction == '1' ? sjei_amount.to_f : 0.0),
                real_credit: (sjei_direction == '-1' ? sjei_amount.to_f : 0.0),
                account: sjei_account,
                name: sjei_label
              }
            end

            entries[number] = {
              printed_on: printed_on,
              journal: c_journal,
              number: line_number,
              currency: journal.currency,
              provider: provider_value,
              items_attributes: attributes
            }
          end
        end

        entries
      end

      # @param [] sage_journal
      # @param [Journal] journal
      def find_or_create_cash(sage_journal, journal)
        number = sage_journal.attribute('CMPTASSOCIE').value
        raw_iban = sage_journal.attribute('IBANPAPIER').value.delete(' ')
        iban = if raw_iban.present? && raw_iban.start_with?('IBAN')
                 Some(raw_iban[4..-1])
               else
                 None()
               end

        Maybe(find_cash_by_provider(number))
          .recover { create_cash(number, journal: journal, iban: iban) }
      end

      def find_cash_by_provider(account_number)
        unwrap_one(:cash) do
          Cash.of_provider_name(provider_vendor, provider_name)
              .of_provider_data('account_number', account_number)
        end
      end

      # @param [String] account_number
      # @param [Journal] journal
      # @param [Maybe<String>] iban
      # @return [Cash]
      def create_cash(account_number, journal:, iban:)
        main_account = find_or_create_account(account_number, journal.name)

        cash_attributes = {
          name: 'enumerize.cash.nature.bank_account'.t,
          nature: 'bank_account',
          journal: journal,
          provider: provider_value(account_number: account_number)
        }

        iban.fmap do |i|
          cash_attributes.merge!(iban: i)
        end

        Cash.create_with(cash_attributes)
            .find_or_create_by(main_account: main_account)
      end

      # @param [String] jou_code
      # @param [String] jou_name
      # @param [Symbol] jou_nature
      # @return [Journal]
      def find_or_create_journal(jou_code, jou_name, jou_nature)
        Maybe(find_journal_by_provider(jou_code))
          .recover { find_journal_by_name(jou_name, expected_nature: jou_nature) }
          .recover { create_journal(jou_code, jou_name, jou_nature) }
          .or_raise
      end

      # @param [String] name
      # @param [Symbol] expected_nature
      # @return [Journal, nil]
      def find_journal_by_name(name, expected_nature:)
        journal = unwrap_one('journal') { Journal.where(name: name) }

        if journal.present? && journal.nature != expected_nature
          raise StandardError, tl(:errors, :expected_nature_journal, name: name, expected_nature: expected_nature, nature: journal.nature)
        end

        journal
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
          Journal.of_provider_name(provider_vendor, provider_name)
                 .of_provider_data(:journal_code, code)
        end
      end

      protected

        def tl(*unit, **options)
          I18n.t("exchanger.sage.i_seven.#{unit.map(&:to_s).join('.')}", **options)
        end

        def unwrap_one(name, exact: false, &block)
          results = block.call
          size = results.size

          if size > 1
            raise UniqueResultExpectedError, "Expected only one #{name}, got #{size}"
          elsif exact && size == 0
            raise UniqueResultExpectedError, "Expected only one #{name}, got none"
          else
            results.first
          end
        end

        # @return [Accountancy::AccountNumberNormalizer]
        def account_normalizer
          @account_normalizer ||= Accountancy::AccountNumberNormalizer.build
        end

        # @return [Import]
        def import_resource
          @import_resource ||= Import.find(options[:import_id])
        end

        def provider_value(**data)
          { vendor: provider_vendor, name: provider_name, id: import_resource.id, data: { sender_infos: file_info.version_information, **data } }
        end

        def provider_name
          :journal_entries
        end

        def provider_vendor
          :i_seven_sage
        end
    end
  end
end
