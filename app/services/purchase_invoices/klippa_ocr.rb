# frozen_string_literal: true

module PurchaseInvoices
  class KlippaOcr

    BASE_URL = 'https://custom-ocr.klippa.com/api/v1'
    API_KEY = ENV['KLIPPA_API_KEY']
    CREDIT_URL = '/credits'
    TEMPLATE_URL = '/templates'
    FIELD_URL = '/fields'
    PARSE_URL = '/parseDocument'

    def initialize
      @params = { 'X-Auth-Key': API_KEY, accept: :json }
    end

    # return number of credits
    def pull_credits
      url = BASE_URL + CREDIT_URL
      call = RestClient.get(url, headers=@params)
      response = JSON.parse(call.body).deep_symbolize_keys
      if response[:result] == "success"
        response[:data][:AvailableCredits]
      else
        nil
      end
    end

    # return availables templates
    def pull_templates
      url = BASE_URL + TEMPLATE_URL
      call = RestClient.get(url, headers=@params)
      response = JSON.parse(call.body).deep_symbolize_keys
      if response[:result] == "success"
        response[:data][:templates]
      else
        nil
      end
    end

    # return fields or fields for a specific template
    def pull_fields(template_id = nil)
      url = BASE_URL + FIELD_URL
      if template_id
        url += "/#{template_id.to_s}"
      end
      call = RestClient.get(url, headers=@params)
      response = JSON.parse(call.body).deep_symbolize_keys
      if response[:result] == "success"
        response[:data]
      else
        nil
      end
    end

    # return a fields based on a document from Ekylibre Document model
    def post_document_and_parse(document)
      url = BASE_URL + PARSE_URL
      payload = {}
      payload['user_data'] = build_user_data.deep_stringify_keys
      payload['pdf_text_extraction'] = 'full'
      payload['document'] = File.new(document.file.path, 'rb')
      payload['user_data_set_external_id'] = document.id
      call = RestClient.post(url, payload, headers=@params)
      response = JSON.parse(call.body).deep_symbolize_keys
      meta = response[:result] == "success" ? response[:data] : nil
      document.update!(klippa_metadata: meta)
    end

    # return hash for know attributes data before parsing document
    # see https://custom-ocr.klippa.com/docs#section/Userdata
    def build_user_data
      company = Entity.of_company
      # build client user data
      client_data = {}
      client_data[:name] = company.full_name
      client_data[:coc_number] = company.siret_number if company.siret_number.present?
      if company.default_mail_address.present?
        client_data[:zipcode] = company.default_mail_address.mail_line_6_code if company.default_mail_address.mail_line_6_code.present?
        client_data[:city] = company.default_mail_address.mail_mail_line_6_city if company.default_mail_address.mail_mail_line_6_city.present?
        client_data[:country] = company.default_mail_address.mail_country.upcase if company.default_mail_address.mail_country.present?
      end
      client_data[:email] = company.default_email_address.coordinate if company.default_email_address.present?
      # build main user data
      user_data = {}
      user_data[:client] = client_data
      user_data[:transaction_type] = 'purchase'
      user_data[:locale] = { language: 'FR', country: 'fr' }
      user_data
    end

  end
end
