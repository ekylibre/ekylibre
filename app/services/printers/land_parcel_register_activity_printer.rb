module Printers
  class LandParcelRegisterActivityPrinter < LandParcelRegisterPrinterBase

    attr_accessor :campaign, :activity

    def initialize(*_args, campaign:, activity:, template:, **_options)
      super(template: template)

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