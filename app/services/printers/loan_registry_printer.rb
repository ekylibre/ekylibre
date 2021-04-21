# frozen_string_literal: true

module Printers
  class LoanRegistryPrinter < PrinterBase
    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(stopped_on:)
        stopped_on
      end
    end

    def initialize(*_args, started_on:, stopped_on:, template:, **_options)
      super(template: template)
      @started_on = Date.parse started_on
      @stopped_on = Date.parse stopped_on
    end

    def key
      self.class.build_key(stopped_on: @stopped_on.to_s)
    end

    def document_name
      "#{template.nature.human_name} (#{:at.tl} #{@stopped_on.l})"
    end

    def compute_dataset
      loans = Loan.ongoing_within(@started_on.to_time, @stopped_on.to_time).reorder(:started_on)
      loans_data = loans.map do |loan|
        {
          name: loan.name,
          started_on: loan.started_on,
          amount: as_currency(loan.amount),
          interest_percentage: loan.interest_percentage,
          duration: "#{loan.repayment_duration} #{loan.repayment_period.human_name}",
          repayment_method: loan.repayment_method.human_name,
          lender: loan.lender.name,
          account: loan.loan_account.name,
          remaining: as_currency(loan.current_remaining_amount(@stopped_on))
        }
      end
      {
        loans: loans_data,
        totals: {
          amount: as_currency(loans.sum(&:amount)),
          remaining: as_currency( loans.sum { |loan| loan.current_remaining_amount(@stopped_on) })
        },
        company_address: Entity.of_company.default_mail_address&.coordinate
      }.to_struct
    end

    def currency
      @currency ||= Onoma::Currency.find(Preference[:currency])
    end

    def as_currency(value)
      value.l(currency: currency.name, precision: 2)
    end

    def generate(r)
      dataset = compute_dataset
      r.add_field 'COMPANY_ADDRESS', dataset.company_address
      r.add_field 'DOCUMENT_NAME', document_name
      r.add_field 'FILE_NAME', key
      r.add_field 'STOPPED_ON', @stopped_on.to_date.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_table('Loans', dataset.loans) do |t|
        t.add_column(:name) { |loan| loan[:name] }
        t.add_column(:started_on) { |loan| loan[:started_on] }
        t.add_column(:amount) { |loan| loan[:amount] }
        t.add_column(:interest_percentage) { |loan| loan[:interest_percentage] }
        t.add_column(:duration) { |loan| loan[:duration] }
        t.add_column(:repayment_method) { |loan| loan[:repayment_method] }
        t.add_column(:lender) { |loan| loan[:lender] }
        t.add_column(:account) { |loan| loan[:account] }
        t.add_column(:remaining) { |loan| loan[:remaining] }
      end
      r.add_field :total_amt, dataset[:totals][:amount]
      r.add_field :total_rmn, dataset[:totals][:remaining]
    end
  end
end
