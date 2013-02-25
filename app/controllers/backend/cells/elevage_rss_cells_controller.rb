class Backend::Cells::ElevageRssCellsController < Backend::CellsController
  require "feedzirra"

  def show
    @feed = Feedzirra::Feed.fetch_and_parse('http://www.lafranceagricole.fr/Rss/elevage/actu-elevage-14652.html')
  end

end
