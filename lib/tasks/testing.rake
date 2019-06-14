Rake::Task['test:run'].clear

SLOW_TESTS = %w[
  AccountTest
  AggeratioTest
  Backend::AccountsControllerTest
  Backend::ActivitiesControllerTest
  Backend::JournalEntriesControllerTest
  Backend::MattersControllerTest
  Backend::ProductNatureVariantsControllerTest
  Backend::ProductNaturesControllerTest
  Backend::SalesControllerTest
  CharentesAlliance::IncomingDeliveriesExchangerTest
  CustomFieldTest
  Ekylibre::AccountsExchangerTest
  Ekylibre::FirstRunTest
  Ekylibre::SettingsExchangerTest
  Ekylibre::TenantTest
  FIEA::GalacteaExchangerTest
  FinancialYearCloseTest
  FinancialYearTest
  FinancialYearTest::CloseTest
  FixturesTest
  Lilco::MilkAnalysesExchangerTest
  PdfPrinterTest
  Synel::AnimalsExchangerTest
  TaxDeclarationItemTest
  UPRA::ReproductorsExchangerTest
].freeze

def slow_test_paths
  SLOW_TESTS.map { |test| 'test/**/' + test.underscore + '.rb' }
end

namespace :test do
  # desc 'Run tests for libraries'
  Rails::TestTask.new(lib: 'test:prepare') do |t|
    t.pattern = 'test/lib/**/*_test.rb'
  end

  # desc 'Run tests for exchangers'
  Rails::TestTask.new(exchangers: 'test:prepare') do |t|
    t.pattern = 'test/exchangers/**/*_test.rb'
  end

  # desc 'Run tests for services'
  Rails::TestTask.new(services: 'test:prepare') do |t|
    t.pattern = 'test/services/**/*_test.rb'
  end

  # desc 'Run tests for concepts'
  Rails::TestTask.new(concepts: 'test:prepare') do |t|
    t.pattern = 'test/concepts/**/*_test.rb'
  end

  Rails::TestTask.new(slow: 'test:prepare') do |t|
    t.test_files = slow_test_paths
  end

  Rails::TestTask.new(fast: 'test:prepare') do |t|
    t.test_files = FileList['test/**/*_test.rb'].exclude(slow_test_paths)
  end

  task javascripts: [:teaspoon]
  task core: ['test:units', 'test:functionals', 'test:lib']

  # Append test for lib
  task run_all: ['test:units', 'test:functionals', 'test:integration', 'test:lib', 'test:javascripts']

  task full: ['test:models', 'test:controllers', 'test:frontend', 'test:libs']

  task frontend: ['test:integration', 'test:javascripts']

  task libs: ['test:helpers', 'test:lib', 'test:exchangers', 'test:services', 'test:concepts', 'test:jobs']
end
