class ExportJob < ActiveJob::Base
  queue_as :default

  def perform(aggregator)
    binding.pry
  end
end
