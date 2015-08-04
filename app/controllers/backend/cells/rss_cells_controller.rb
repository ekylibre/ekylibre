class Backend::Cells::RssCellsController < Backend::Cells::BaseController
  def show
    require 'feedjira' unless defined? Feedjira
    @feed = Feedjira::Feed.fetch_and_parse(params[:url])
  end
end
