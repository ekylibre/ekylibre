class Backend::Cells::RssCellsController < Backend::CellsController

  def show
    @feed = Feedzirra::Feed.fetch_and_parse(params[:url])
  end

end
