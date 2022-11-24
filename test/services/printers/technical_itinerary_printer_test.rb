require 'test_helper'

module Printers
  class TechnicalItineraryPrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      I18n.locale = :fra
      Preference.set!(:currency, 'EUR')
      @template = build_stubbed(:document_template,
                                nature: :technical_itinerary_sheet,
                                managed: true)
    end

    test 'should print an technical itinerary sheet' do
      campaign = campaigns(:campaigns_008)
      activity = activities(:activities_001)
      begin
        itk_service = ::TechnicalItineraries::Itk::ImportItkFromLexiconService.new(activity_ids: [activity.id], campaign: campaign)
        itk_service.perform
        ti = TechnicalItinerary.find_by(activity: activity)
      rescue => error
        puts error.inspect.red
      end

      assert ti.valid?, "Technical itinerary must be valid (#{ti.errors.inspect})"

      printer = Printers::TechnicalItineraryPrinter.new(template: @template, campaign: campaign, technical_itinerary_ids: [ti.id])
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end

  end
end
