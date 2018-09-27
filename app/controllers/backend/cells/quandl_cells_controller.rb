require 'quandl'
module Backend
  module Cells
    class QuandlCellsController < Backend::Cells::BaseController
      def show
        finished = '2017-12-31'
        started = '2017-01-01'
        # params[:threshold] = 183.50
        api_key = ENV['QUANDL_API_KEY']
        Quandl::ApiConfig.api_key = api_key
        # Quandl::ApiConfig.api_version = '2015-04-09'
        dataset = params[:dataset] || 'CHRIS/LIFFE_EBM4'
        identifier = Identifier.find_by(nature: :quandl_token)
        token = (identifier ? identifier.value : api_key)
        @data = Quandl::Dataset.get(dataset).data(params: { start_date: started, end_date: finished, order: 'asc' })
        @data if @data.any?
      end
    end
  end
end
