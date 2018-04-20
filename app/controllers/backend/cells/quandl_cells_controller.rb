require 'quandl'
module Backend
  module Cells
    class QuandlCellsController < Backend::Cells::BaseController
      def show
        finished = '2017-12-31'
        started = '2017-01-01'
        # params[:threshold] = 183.50
        Quandl::ApiConfig.api_key = 'UcczgS4H7VXfcqN6-GgM'
        # Quandl::ApiConfig.api_version = '2015-04-09'
        dataset = params[:dataset] || 'CHRIS/LIFFE_EBM4'
        identifier = Identifier.find_by(nature: :quandl_token)
        token = (identifier ? identifier.value : 'UcczgS4H7VXfcqN6-GgM')
        @data = Quandl::Dataset.get(dataset).data(params: { start_date: started, end_date: finished, order: 'asc'})
        if @data.any?
          @data
        else
          nil
        end
      end
    end
  end
end
