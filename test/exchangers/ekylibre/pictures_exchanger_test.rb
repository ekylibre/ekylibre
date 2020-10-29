require 'test_helper'

module Ekylibre
  class PicturesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::PicturesExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'pictures.zip')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
