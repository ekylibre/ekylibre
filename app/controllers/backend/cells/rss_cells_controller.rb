class Backend::Cells::RssCellsController < Backend::CellsController

  def show
    @feed = Feedjira::Feed.fetch_and_parse(params[:url])
  end

end
