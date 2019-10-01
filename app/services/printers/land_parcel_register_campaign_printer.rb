module Printers
  class LandParcelRegisterCampaignPrinter < LandParcelRegisterPrinterBase

    attr_accessor :campaign

    def initialize(*args, campaign:, **option)
      super
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