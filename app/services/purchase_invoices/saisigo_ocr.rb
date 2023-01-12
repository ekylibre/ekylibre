# frozen_string_literal: true

module PurchaseInvoices
  class SaisigoOcr

    BASE_URL = 'https://europe-west1-certain-fly-255208.cloudfunctions.net/Ekylibre_receiver_http'
    KEY_PATH = 'ekylibre_saisigo_keys.json'

    def initialize
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(KEY_PATH),
        scope: BASE_URL
      )

      token_call = authorizer.fetch_access_token!
      @token = token_call['id_token']
      @params = { authorization: "Bearer #{@token}", content_type: :json }
    end

    # return a fields based on a document from Ekylibre Document model
    def post_document_and_parse(document)
      url = BASE_URL
      payload = File.open(document.file.path, 'rb')
      call = RestClient.post(url, payload, headers=@params)
      if call.code == 200
        response = JSON.parse(call.body).deep_symbolize_keys
        if response[:result] == "ok"
          document.update!(klippa_metadata: meta)
          { status: :success, message: :successfully_document_transformation }
        else
          { status: :warning, message: :stand_by_document_transformation }
        end
      else
        { status: :error, message: :network_error }
      end
    end

  end
end
