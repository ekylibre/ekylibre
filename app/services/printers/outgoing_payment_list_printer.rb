# frozen_string_literal: true

module Printers
  class OutgoingPaymentListPrinter < PrinterBase
    AMOUNT_OF_ROWS_FITTING_IN_PAGE_ONE = 8
    AMOUNT_OF_ROWS_FITTING_IN_OTHER_PAGES = 16

    attr_accessor :template_path, :outgoing_payment_list

    def initialize(outgoing_payment_list:, nature:, template:)
      super(template: template)

      @outgoing_payment_list = outgoing_payment_list
      @nature = nature
    end

    def key
      outgoing_payment_list.number
    end

    def compute_dataset
      details = []
      checks = []

      @outgoing_payment_list.payments.each do |payment|
        invoices = payment.affair.purchase_invoices.map do |invoice|
          { reference_number: invoice.reference_number,
            number: invoice.number,
            invoiced_at: invoice.invoiced_at.to_date.l,
            pretax_amount: invoice.pretax_amount,
            amount: invoice.amount }
        end

        company = Entity.of_company
        company_town = company.mails.any? ? company.mails.where(by_default: true).first.mail_line_6.split(' ').last : ''
        payee_address = payment.payee.mails.any? ? payment.payee.mails.where(by_default: true).first.mail_coordinate : payment.payee.full_name

        details << { number: payment.number,
                     amount: payment.amount,
                     currency: payment.currency,
                     payee: payment.payee.full_name,
                     payee_address: payee_address.mb_chars.upcase,
                     bank_check_number: payment.bank_check_number ? I18n.translate('labels.bank_check_number', number: payment.bank_check_number) : '',
                     bank_check_number_text: payment.bank_check_number ? I18n.translate('labels.bank_check_number_text', number: payment.bank_check_number) : '',
                     responsible: payment.responsible.name,
                     text: I18n.translate('labels.outgoing_payment_list_text', amount: payment.amount, currency: payment.currency),
                     invoices: invoices }

        checks << { amount: "**#{payment.amount}#{payment.currency}**",
                    amount_to_letter: "**#{payment.amount_to_letter}**",
                    paid_at: payment.paid_at.to_date.l,
                    payee: payment.payee.full_name,
                    company_town: I18n.transliterate(company_town).upcase }

        invoices_count = invoices.count

        if invoices_count > AMOUNT_OF_ROWS_FITTING_IN_PAGE_ONE
          amount_left_to_display = invoices_count - AMOUNT_OF_ROWS_FITTING_IN_PAGE_ONE
          amount_of_pages_needed = (amount_left_to_display.to_f / AMOUNT_OF_ROWS_FITTING_IN_OTHER_PAGES).ceil
          amount_of_pages_needed.times do
            checks << {}
          end
        end
      end
      { details: details, checks: checks }
    end

    def generate(r)
      dataset = compute_dataset
      file_name = "#{I18n.translate('nomenclatures.document_natures.items.outgoing_payment_list')} (#{@outgoing_payment_list.number})"
      options = @nature == 'check_letter' ? { checks: dataset[:checks] } : {}

      company = Entity.of_company
      company_address = company.mails.any? ? company.mails.where(by_default: true).first.mail_coordinate : company.full_name
      company_email = company.emails.any? ? company.emails.where(by_default: true).first.coordinate : ''
      company_website = company.websites.any? ? company.websites.where(by_default: true).first.coordinate : ''

      r.add_field :printed_at, Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_image :company_logo, company.picture.path if company.picture.path
      r.add_field :company_address, company_address.mb_chars.upcase
      r.add_field :company_email, company_email
      r.add_field :company_website, company_website

      r.add_section('Section1', dataset[:details]) do |s|
        s.add_field(:payee) { |detail| detail[:payee] }
        s.add_field(:payee_address) { |detail| detail[:payee_address] }
        s.add_field(:number) { |detail| detail[:number] }
        s.add_field(:currency) { |detail| detail[:currency] }
        s.add_field(:amount) { |detail| detail[:amount] }
        s.add_field(:bank_check_number) { |detail| detail[:bank_check_number] }
        s.add_field(:bank_check_number_text) { |detail| detail[:bank_check_number_text] }
        s.add_field(:responsible) { |detail| detail[:responsible] }
        s.add_field(:text) { |detail| detail[:text] }

        s.add_table('Table2', :invoices) do |t|
          t.add_column(:reference_number) { |invoice| invoice[:reference_number] }
          t.add_column(:number) { |invoice| invoice[:number] }
          t.add_column(:invoiced_at) { |invoice| invoice[:invoiced_at] }
          t.add_column(:pretax_amount) { |invoice| invoice[:pretax_amount] }
          t.add_column(:amount) { |invoice| invoice[:amount] }
        end
      end
    end
  end
end
