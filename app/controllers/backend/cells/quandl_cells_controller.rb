module Backend
  module Cells
    class QuandlCellsController < Backend::Cells::BaseController
      def show
        start = Time.zone.today << 12
        finish = start >> 12 - 1
        # params[:threshold] = 183.50
        dataset = params[:dataset] || 'CHRIS/LIFFE_EBM4'
        identifier = Identifier.find_by(nature: :quandl_token)
        token = (identifier ? identifier.value : 'BwQESxTYjPRj58EbvzQA')
        url = "https://www.quandl.com/api/v1/datasets/#{dataset}.json?auth_token=#{token}&trim_start=#{start}&trim_end=#{finish}"
        url = "https://www.quandl.com/api/v1/datasets/#{dataset}.json?auth_token=#{token}"
        data = JSON.parse(open(url))
        if data['errors'].any?
        # TODO: Prevent ?
        else
          @data = data.deep_symbolize_keys
        end
      end
    end
  end
end
