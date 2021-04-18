require 'rss'
require 'open-uri'

module Backend
  module Cells
    class RssCellsController < Backend::Cells::BaseController
      def show
        # Make Web-agri RSS feed by default for the moment
        rss_url = "https://www.web-agri.fr/rss"
        @feed = RSS::Parser.parse(URI.parse(rss_url).open.read, false)
      rescue => e
        @error = :informations_feed_is_unreachable.tn(url: rss_url, message: e.message)
      end
    end
  end
end
