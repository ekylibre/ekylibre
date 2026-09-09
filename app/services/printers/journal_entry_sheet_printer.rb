# frozen_string_literal: true

module Printers
  # Replaces the Jasper template config/locales/fra/reporting/journal_entry_sheet.jrxml,
  # which consumed `JournalEntry#to_xml`. The fields below mirror the ones that
  # template declared.
  class JournalEntrySheetPrinter < PrinterBase
    # for accessing to number_to_accountancy
    include ApplicationHelper

    class << self
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # @param [JournalEntry] journal_entry
    def initialize(*_args, journal_entry:, template:, **_options)
      super(template: template)

      @journal_entry = journal_entry
    end

    def key
      self.class.build_key(id: @journal_entry.id, updated_at: @journal_entry.updated_at.to_s)
    end

    def document_name
      "#{template.nature.human_name} - #{@journal_entry.number}"
    end

    def compute_dataset
      {
        entry: @journal_entry,
        items: @journal_entry.items.order(:position),
        company: Entity.of_company
      }
    end

    def generate(report)
      dataset = compute_dataset
      entry = dataset[:entry]
      company = dataset[:company]

      report.add_field 'DOCUMENT_NAME', document_name
      report.add_field 'COMPANY_NAME', company&.full_name
      report.add_field 'COMPANY_ADDRESS', company&.default_mail_address&.coordinate
      report.add_field 'NUMBER', entry.number
      report.add_field 'PRINTED_ON', entry.printed_on&.l
      report.add_field 'STATE', entry.state_label
      report.add_field 'JOURNAL_NAME', entry.journal&.name
      report.add_field 'JOURNAL_CODE', entry.journal&.code
      report.add_field 'FINANCIAL_YEAR_CODE', entry.financial_year&.code
      report.add_field 'CURRENCY', entry.currency
      report.add_field 'REAL_DEBIT', number_to_accountancy(entry.real_debit)
      report.add_field 'REAL_CREDIT', number_to_accountancy(entry.real_credit)
      report.add_field 'RESOURCE_NUMBER', entry.resource&.number
      report.add_field 'CREATED_AT', entry.created_at&.l
      report.add_field 'UPDATED_AT', entry.updated_at&.l
      report.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

      report.add_table('ITEMS', dataset[:items], header: true) do |t|
        t.add_column(:position, &:position)
        t.add_column(:account_number) { |item| item.account&.number }
        t.add_column(:name, &:name)
        t.add_column(:letter, &:letter)
        t.add_column(:tax_name) { |item| item.tax&.name }
        t.add_column(:item_real_debit) { |item| number_to_accountancy(item.real_debit) }
        t.add_column(:item_real_credit) { |item| number_to_accountancy(item.real_credit) }
      end
    end
  end
end
