require 'test_helper'

module Printers
  class InterventionRegisterPrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @template = Minitest::Mock.new
      @template.expect :nature, :intervention_register
      @template.expect :nature, Onoma::DocumentNature[:intervention_register]
      @template.expect :nil?, false
      @template.expect :managed?, true
    end

    teardown do
      @template.verify
    end

    test 'should print an intervention register by campaign' do
      campaign = campaigns(:campaigns_006)
      assert campaign.valid?, "Fixture campaign is not valid (#{campaign.errors.inspect})"

      printer = Printers::InterventionRegisterPrinter.new(template: @template, campaign: campaign)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end

    test 'should print an intervention register by campaign and activity' do
      campaign = campaigns(:campaigns_001)
      activity = activities(:activities_001)
      assert campaign.valid?, "Fixture campaign is not valid (#{campaign.errors.inspect})"
      assert activity.valid?, "Fixture activity is not valid (#{activity.errors.inspect})"

      printer = Printers::InterventionRegisterActivityPrinter.new(template: @template, campaign: campaign, activity: activity)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end

  end
end
