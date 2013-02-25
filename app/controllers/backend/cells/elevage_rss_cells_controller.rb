class Backend::Cells::ElevageRssCellsController < Backend::CellsController
  require "feedzirra"

  def show
    @feeds = Feedzirra::Feed.fetch_and_parse('http://www.lafranceagricole.fr/Rss/elevage/actu-elevage-14652.html')
    #feed.entries.each do |entry|
    #puts "#{entry.title}\n#{entry.description}\n\n"
    #end
  end

end