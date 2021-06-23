require 'test_helper'

module Printers
  class ActivityCostPrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @template = Minitest::Mock.new
      @template.expect :nature, :activity_cost
      @template.expect :nature, Onoma::DocumentNature[:activity_cost]
      @template.expect :nil?, false
      @template.expect :managed?, true
    end

    teardown do
      @template.verify
    end

    test 'should print an activity cost by campaign' do
      campaign = campaigns(:campaigns_006)
      assert campaign.valid?, "Fixture campaign is not valid (#{campaign.errors.inspect})"

      printer = Printers::ActivityCostPrinter.new(template: @template, campaign: campaign)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end

    test 'should print an activity cost by campaign and activity' do
      campaign = campaigns(:campaigns_001)
      activity = activities(:activities_001)
      assert campaign.valid?, "Fixture campaign is not valid (#{campaign.errors.inspect})"
      assert activity.valid?, "Fixture activity is not valid (#{activity.errors.inspect})"

      printer = Printers::ActivityCostPrinter.new(template: @template, campaign: campaign, activity: activity)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end

  end
end
