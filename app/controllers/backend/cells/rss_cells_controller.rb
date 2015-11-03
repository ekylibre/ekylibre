require 'feedjira'

class Backend::Cells::RssCellsController < Backend::Cells::BaseController
  def show
    @feed = Feedjira::Feed.fetch_and_parse(params[:url]) if params[:url]
  end
end
