require 'test_helper'

module Isagri
  module Isacompta
    class ExportExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Isagri::Isacompta::ExportExchanger.import(fixture_files_path.join('imports', 'isagri', 'isacompta', 'export.isa'))
      end
    end
  end
end
