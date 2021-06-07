# frozen_string_literal: true

module Printers
  class InterventionRegisterActivityPrinter < InterventionRegisterPrinter

    def initialize(*_args, template:, **options)
      super(template: template)
      @campaign = options[:campaign]
      @activity = options[:activity]
    end

    #  Generate document name
    def document_name
      "#{template.nature.human_name} : #{@campaign.name}"
    end

    #  Create document key
    def key
      self.class.build_key(campaign: @campaign, activity: @activity)
    end

  end
end
