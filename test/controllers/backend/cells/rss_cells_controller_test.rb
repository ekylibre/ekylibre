require 'test_helper'
class Backend::Cells::RssCellsControllerTest < ActionController::TestCase
  test_restfully_all_actions show: { params: { url: 'https://fr.wikipedia.org/w/index.php?title=ekylibre&action=history&feed=rss' } }
end
