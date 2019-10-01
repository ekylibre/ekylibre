module Printers
  class LandParcelRegisterActivityPrinter < LandParcelRegisterPrinterBase

    attr_accessor :campaign, :activity

    def initialize(*args, campaign:, activity:, **options)
      super
      @campaign = campaign
      @activity = activity
    end

    def get_productions_for_dataset
      activity.productions.of_campaign(campaign)
    end

    def key
      self.class.build_key campaign: campaign, activity: activity
    end
  end
end