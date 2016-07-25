require 'test_helper'
require 'generators/renaming_migration/renaming_migration_generator'

class RenamingMigrationGeneratorTest < Rails::Generators::TestCase
  tests RenamingMigrationGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
