require 'test_helper'

module Isagri
  module Isacompta
    class FixedAssetsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Isagri::Isacompta::FixedAssetsExchanger.import(fixture_files_path.join('imports', 'isagri', 'isacompta', 'fixed_assets.csv'))
      end
    end
  end
end
