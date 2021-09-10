class DailyChargeJob < ActiveJob::Base
  queue_as :default

  def perform(activity_production)
    iterator = TechnicalItineraries::DailyChargesCreationInteractor
                 .call({ activity_production: activity_production })

    puts "Daily charges created with success" if iterator.success?
    puts "Daily charges job failed!" if iterator.fail?
  end
end
