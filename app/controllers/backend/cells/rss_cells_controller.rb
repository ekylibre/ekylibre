require 'feedjira'

class Backend::Cells::RssCellsController < Backend::Cells::BaseController
  def show
    if params[:url]
      @feed = Feedjira::Feed.fetch_and_parse(params[:url])
    end
  end
end
