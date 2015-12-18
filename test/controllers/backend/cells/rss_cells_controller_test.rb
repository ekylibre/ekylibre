require 'test_helper'
module Backend
  module Cells
    class RssCellsControllerTest < ActionController::TestCase
      test_restfully_all_actions show: { params: { url: 'https://fr.wikipedia.org/w/index.php?title=ekylibre&action=history&feed=rss' } }
    end
  end
end
