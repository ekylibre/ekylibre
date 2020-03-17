require 'test_helper'

module Isagri
  module Isacompta
    class ExportExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = Isagri::Isacompta::ExportExchanger.build(fixture_files_path.join('imports', 'isagri', 'isacompta', 'export.isa')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
