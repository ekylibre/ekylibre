require 'test_helper'

module ImportTest
  class DummyExchangerExistsTest < Ekylibre::Testing::ApplicationTestCase
    test "the nature exists" do
      ActiveExchanger::Base.find('import_test_import_test_dummy')
    end
  end

  class ImportExchangerTest < Ekylibre::Testing::ApplicationTestCase

    setup do
      Dir.mktmpdir do |dir|
        path = Pathname.new(dir).join('dummy.csv')
        File.write(path, "42")

        @import = Import.create!(nature: :import_test_import_test_dummy, archive: File.new(path))
      end
    end

    test "Import should not run if check returns false" do
      check_executed = false
      import_executed = false
      ImportTestDummyExchanger.check_block = -> {
        check_executed = true
        false
      }
      ImportTestDummyExchanger.import_block = -> {
        import_executed = true
      }

      @import.run

      assert check_executed
      refute import_executed
    end

    test "Import should not run if check raises" do
      import_executed = false
      ImportTestDummyExchanger.check_block = -> { raise StandardError.new }
      ImportTestDummyExchanger.import_block = -> {
        import_executed = true
      }

      @import.run

      refute import_executed
    end

    test "Import should run if check returns false" do
      check_executed = false
      import_executed = false
      ImportTestDummyExchanger.check_block = -> {
        check_executed = true
        true
      }
      ImportTestDummyExchanger.import_block = -> {
        import_executed = true
      }

      @import.run

      assert check_executed
      assert import_executed
    end

    test "Import should have state aborted when check has returned false" do
      ImportTestDummyExchanger.check_block = -> { false }

      @import.run

      assert_equal :aborted, @import.state.to_sym
    end

  end
end