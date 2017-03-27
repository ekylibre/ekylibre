require 'test_helper'

module Isagri
  module Isacompta
    class FixedAssetsExchangerTest < ::ActiveExchanger::TestCase
      test 'import' do
        ::ActiveExchanger::Base.import(:isagri_isacompta_fixed_assets, fixture_files_path.join('imports', 'isagri_isacompta_fixed_assets.csv'))
      end
    end
  end
end
