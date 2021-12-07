# frozen_string_literal: true

module Interventions
  module Phytosanitary
    class PfiClientApi
      attr_reader :campaign, :activity, :intervention_parameter_input, :area_ratio, :activities

      class << self
        def down?
          RestClient.get('https://alim-pprd.agriculture.gouv.fr/ift-api/api/hello')&.code != 200
        end
      end

      # set urls for accessing IFT-API
      # https://alim.agriculture.gouv.fr/ift-api/swagger-ui.html
      if Rails.env.production?
        BASE_URL = "https://alim.agriculture.gouv.fr/ift-api"
      else
        BASE_URL = "https://alim-pprd.agriculture.gouv.fr/ift-api"
      end
      PFI_CAMPAIGN_URL = "/api/campagnes"
      PFI_COMPUTE_URL = "/api/ift/traitement"
      PFI_COMPUTE_SIGN_URL = "/api/ift/traitement/certifie"
      PFI_REPORT_PDF_URL = "/api/ift/bilan/pdf"

      # transcode unit between IFT-API and Ekylibre
      TRANSCODE_UNIT = {
                        kilogram_per_hectare: "U1", # KG/HA
                        kilogram_per_hectoliter: "U2", # KG/HL
                        liter_per_hectare: "U3", # L/HA
                        liter_per_hectoliter: "U4", # L/HL
                        unit_per_hectare: "U5", # Unité/HA
                        unit_per_hectoliter: "U8" # Unité/HL
                        }.freeze

      # @param [Campaign] campaign
      # @param [Activity] activity
      # @param [InterventionInput] intervention_parameter_input
      # @param [Decimal] area_ratio
      # @param [<<Array>> Activity] activities
      # @param [String] report_title
      def initialize(campaign:, activity: nil, intervention_parameter_input: nil, area_ratio: 100, activities: nil, report_title: nil)
        @campaign = campaign
        @activity = activity
        @intervention_parameter_input = intervention_parameter_input
        @area_ratio = area_ratio
        # for pdf pfi report only
        @activities = activities.of_families(%i[plant_farming vine_farming]) if activities
        @report_title = report_title || @campaign.name
      end

      # Compute pfi for one input on intervention
      # @param [Boolean] with_signature
      # @return [JSON api_response, nil]
      def compute_pfi(with_signature: true, with_notify: false)
        @notify_user = with_notify
        return nil if @activity.nil? || @intervention_parameter_input.nil? || @intervention_parameter_input.product&.variant&.phytosanitary_product&.adjuvant?

        # check if campaign is available on api
        begin
          campaign_url = BASE_URL + PFI_CAMPAIGN_URL + "/#{@campaign.harvest_year}"
          RestClient.get campaign_url
        rescue RestClient::ExceptionWithResponse => e
          notify_api_error_to_creator(error: e, log: campaign_url)
          return nil
        end

        # build url if we want signature
        if with_signature == true
          url = BASE_URL + PFI_COMPUTE_SIGN_URL
        else
          url = BASE_URL + PFI_COMPUTE_URL
        end

        # build params and return nil if no mandatory params is set
        p = build_params(@intervention_parameter_input)
        if p
          # call API and get response
          begin
            call = RestClient::Request.execute(method: :get, url: url, headers: { params: p })
            response = JSON.parse(call.body).deep_symbolize_keys
            if response.dig(:iftTraitement, :avertissement)
              notify_api_warnings_to_creator(warning: response[:iftTraitement][:avertissement][:libelle])
            end
            response
          rescue RestClient::ExceptionWithResponse => e
            notify_api_error_to_creator(error: e, log: "headers: #{p}, url: #{url}")
            nil
          end
        else
          nil
        end
      end

      # Compute pfi report for all input on all interventions in each activity production of a campaign
      # @return [JSON {status: ,body: }]
      def compute_pfi_report
        return { status: false, body: :no_activities_found } if @activities.nil?

        # check if activity has production nature
        activities_missing_pn = @activities.where(production_nature: nil)
        if activities_missing_pn.any?
          return { status: :e_activities_production_nature, body: activities_missing_pn.pluck(:name).to_sentence }
        end

        url = BASE_URL + PFI_REPORT_PDF_URL
        params = "?campagneIdMetier=#{grab_harvest_year}&titre=#{@report_title}"
        url << params
        # params["parcellesCultivees"] = build_crops
        body = build_crops
        # call API and get response
        begin
          response = RestClient.post url, body.to_json, content_type: 'application/json'
          { status: true, body: response.body }
          # RestClient::Request.execute(method: :post, url: url, payload: body, headers: params)
        rescue RestClient::ExceptionWithResponse => err
          { status: false, body: err.message }
        end
      end

      private

        # Compute params for API
        # call by compute_pfi
        # @param [InterventionInput] intervention_parameter_input
        # @return [JSON {}]
        def build_params(intervention_input)
          params = {}
          # mandatory params for API
          params["campagneIdMetier"] = grab_harvest_year
          params["cultureIdMetier"] = grab_pfi_crop_code(@activity)
          params["typeTraitementIdMetier"] = grab_pfi_treatment_nature(intervention_input)

          # check mandatory params is present
          params.each do |_k, v|
            if v.nil? || v.blank?
              return nil
              # raise StandardError.new(:missing_mandatory_attribute, attribute: k, value: v)
            end
          end

          normalized_unit = grab_normalized_quantity(intervention_input)
          if normalized_unit
            # not mandatory for API
            params["numeroAmmIdMetier"] = grab_france_maaid_from_usage(intervention_input) if grab_france_maaid_from_usage(intervention_input)
            params["uniteIdMetier"] = TRANSCODE_UNIT[normalized_unit.unit.to_sym] if normalized_unit
            params["dose"] = normalized_unit.value.to_f if normalized_unit
            params["facteurDeCorrection"] = @area_ratio
            params["cibleIdMetier"] = grab_pfi_target_nature(intervention_input) if grab_pfi_target_nature(intervention_input)
            params["volumeDeBouillie"] = ""
            params["produitLibelle"] = intervention_input.product.name
          end
          params
        end

        # Compute crops params for API
        # call by compute_pfi_report
        # @return [JSON {}]
        def build_crops
          # compute crop
          crops = {}.with_indifferent_access
          crops["parcellesCultivees"] = []
          @activities.each do |activity|
            ActivityProduction.of_activity(activity).of_campaign(@campaign).each do |ap|
              crop = {}.with_indifferent_access
              crop["type"] = 'parcelle'
              crop["campagne"] = { idMetier: @campaign.harvest_year, libelle: @campaign.name, active: true }
              crop["culture"] = { idMetier: grab_pfi_crop_code(activity), libelle: "", groupeCultures: { idMetier: "", libelle: "" } }
              crop["parcelle"] = { nom: ap.name, surface: ap.support_shape_area.convert(:hectare).to_f.round(2) }
              crop["traitements"] = []
              ap.interventions.of_nature_using_phytosanitary.each do |int|
                int.inputs.each do |intervention_input|
                  treatment = compute_crop_interventions_for_pfi_report(ap, intervention_input)
                  crop["traitements"] << treatment if treatment && !intervention_input.product&.variant&.phytosanitary_product&.adjuvant?
                end
              end
              crops["parcellesCultivees"] << crop
            end
          end
          crops
        end

        # Compute crops params for API
        # call by build_crops
        # @param [ActivityProduction] ap
        # @param [InterventionInput] intervention_input
        # @return [JSON {}]
        def compute_crop_interventions_for_pfi_report(ap, intervention_input)
          product_ids = Product.where(activity_production_id: ap.id).pluck(:id)
          target_ids = InterventionTarget.where(product_id: product_ids).pluck(:id)
          pfi_data = PfiInterventionParameter.find_by(nature: 'crop', input_id: intervention_input.id, target_id: target_ids)
          if pfi_data.present?
            # compute ratio because pfi_crop is relative to product area (plant or land_parcel)
            # pfi_report is relative to activity_production area
            target_area = pfi_data.target&.product&.get(:net_surface_area)
            ap_area = ap.support_shape_area
            target_ap_area_ratio = (target_area.convert(:square_meter).to_f / ap_area.in(:square_meter).to_f).round(2) if target_area && ap_area
            # build body for build_crops
            traitement = pfi_data.response["iftTraitement"]
            if target_ap_area_ratio
              traitement["facteurDeCorrection"] = (traitement["facteurDeCorrection"].to_f * target_ap_area_ratio.to_f).round(2)
            end
            # if traitement["avertissement"]
            # traitement.delete!("avertissement")
            # end
            traitement["id"] = pfi_data.response["id"]
            traitement["date"] = intervention_input.intervention.started_at.strftime("%FT%T.%LZ")
            traitement["dateTraitement"] = intervention_input.intervention.started_at.strftime("%Y-%m-%d")
            traitement
          else
            nil
          end
        end

        def grab_harvest_year
          @campaign.harvest_year || nil
        end

        def grab_pfi_crop_code(activity)
          if activity.production_nature&.pfi_crop
            activity.production_nature&.pfi_crop&.tfi_code
          else
            nil
          end
        end

        def grab_pfi_treatment_nature(intervention_input)
          if intervention_input&.usage&.target_name_label_fra
            pfi_target = intervention_input.usage.pfi_target
            pfi_target.default_pfi_treatment_type_id if pfi_target
          else
            nil
          end
        end

        def grab_pfi_target_nature(intervention_input)
          if intervention_input&.usage&.target_name_label_fra
            pfi_target = intervention_input.usage.pfi_target
            if pfi_target && pfi_target.pfi_id.present?
              pfi_target.pfi_id
            else
              nil
            end
          else
            nil
          end
        end

        def grab_france_maaid_from_usage(intervention_input)
          if intervention_input&.usage&.france_maaid
            intervention_input.usage.france_maaid
          else
            nil
          end
        end

        # return Measure for mass or volume_area_density
        def grab_normalized_quantity(intervention_input)
          quantity_area = intervention_input&.input_quantity_per_area
          if quantity_area
            case quantity_area.dimension
            when :volume_area_density then quantity_area.convert(:liter_per_hectare)
            when :mass_area_density then quantity_area.convert(:kilogram_per_hectare)
            else nil
            end
          else
            nil
          end
        end

        def notify_api_error_to_creator(error: nil, log: "")
          code = error.http_code
          error_message = I18n.t('labels.pfi_client_error', campaign: @campaign.name, activity: @activity.name, input: @intervention_parameter_input.name, intervention: @intervention_parameter_input.intervention.name, loggable: log)
          ExceptionNotifier.notify_exception(error, data: { message: error_message }) if code.to_s == '400'
          if @notify_user
            message = if code.to_s == '404'
                        :pfi_api_down.tl
                      else
                        :pfi_api_error.tl
                      end
            @intervention_parameter_input.intervention.creator.notifications.create!({
              message: message,
              level: :error,
              interpolations: {}
            })
          end
        end

        def notify_api_warnings_to_creator(warning: nil)
          if @notify_user
            @intervention = @intervention_parameter_input.intervention
            @intervention.creator.notifications.create!({
              message: :pfi_api_warnings.tl,
              level: :error,
              interpolations: {
                id: @intervention.id,
                warnings: warning
              }
            })
          end
        end

    end
  end
end
