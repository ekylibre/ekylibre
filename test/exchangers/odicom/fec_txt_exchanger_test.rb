require 'test_helper'

module Odicom
  class FecTxtExchangerTest < ActiveExchanger::TestCase

    setup do
      # We want to keep tracking of import resource
      I18n.locale = :fra
      @import = Import.create!(nature: :odicom_fec_txt, creator: User.first)
      Preference.set!(:account_number_digits, 9)
      n = Accountancy::AccountNumberNormalizer.build(standard_length: 9)
      Account.where.not(nature: "auxiliary").each { |acc| acc.update!(number: n.normalize!(acc.number)) }
    end

    test 'import' do
      result = Odicom::FecTxtExchanger.build(fixture_files_path.join('imports', 'odicom', '123456789FEC20200331.txt'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
    end

    teardown do
      @import.destroy!
    end

  end
end
