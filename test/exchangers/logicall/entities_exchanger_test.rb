require 'test_helper'

module Logicall
  class EntitiesExchangerTest < ActiveExchanger::TestCase
    setup do
      # We want to keep tracking of import resource
      I18n.locale = :fra
      @import = Import.create!(nature: :logicall_entities, creator: User.first)
    end

    test 'import' do
      result = Logicall::EntitiesExchanger.build(fixture_files_path.join('imports', 'logicall', 'entities.csv'), options: { import_id: @import.id }).run
      assert result.success?, [result.message, result.exception]
    end

    teardown do
      @import.destroy!
    end

  end
end
