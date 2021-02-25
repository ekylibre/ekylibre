# frozen_string_literal: true

module Printers
  class LandParcelRegisterCampaignPrinter < LandParcelRegisterPrinterBase
    attr_accessor :campaign

    def initialize(*_args, campaign:, template:, **_options)
      super(template: template)

      @campaign = campaign
    end

    def get_productions_for_dataset
      ActivityProduction.of_campaign(campaign)
    end

    def key
      self.class.build_key campaign: campaign
    end
  end
end
