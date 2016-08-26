require 'test_helper'

module Isagri
  module Isacompta
    class ExportExchangerTest < ::ActiveExchanger::TestCase
      test 'import' do
        ::ActiveExchanger::Base.import(:isagri_isacompta_export, fixture_files_path.join('imports', 'isagri_isacompta_export.isa'))
      end
    end
  end
end
