require 'feedjira'

class Backend::Cells::RssCellsController < Backend::Cells::BaseController
  def show
    @feed = Feedjira::Feed.fetch_and_parse(params[:url]) if params[:url]
  rescue => e
    @error = :informations_feed_is_unreachable.tn(url: params[:url], message: e.message)
  end
end
