module Clients
  module Gouv
    class PfiClient
      # https://api.agriculture.gouv.fr/apimportal/catalog/api/de27a341-e390-34fc-9f09-b3151ae985d2/doc?page=922c6832-907a-4f87-ac68-32907aef8729
      BASE_URL = if Rails.env.production?
                   "https://alim.api.agriculture.gouv.fr/ift/v5".freeze
                 else
                   "https://alim-pprd.api.agriculture.gouv.fr/ift/v5".freeze
                 end
      DEMO_URL = "/api/hello".freeze
      PFI_CAMPAIGN_URL = "/api/campagnes".freeze
      PFI_COMPUTE_URL = "/api/ift/traitement".freeze
      PFI_COMPUTE_SIGN_URL = "/api/ift/traitement/certifie".freeze
      PFI_REPORT_PDF_URL = "/api/ift/bilan/pdf".freeze

      def down?
        response = RestClient.get(BASE_URL + DEMO_URL)
        response.code != 200
      end

      def get_campaign(harvest_year)
        campaign_url = BASE_URL + PFI_CAMPAIGN_URL + "/" + harvest_year
        RestClient.get(campaign_url)
      end

      def compute(params, with_signature: true)
        url = if with_signature
                BASE_URL + PFI_COMPUTE_SIGN_URL
              else
                BASE_URL + PFI_COMPUTE_URL
              end

        call = RestClient::Request.execute(method: :get, url: url, headers: { params: params })
        JSON.parse(call.body).deep_symbolize_keys
      end

      def compute_report(harvest_year, title, body)
        params = "?campagneIdMetier=#{harvest_year}&titre=#{title}"
        url = BASE_URL + PFI_REPORT_PDF_URL + params
        RestClient.post url, body.to_json, { content_type: 'application/json', accept: 'application/pdf' }
      end

    end
  end
end
