require 'test_helper'

module FinancialYearTest
  class CloseTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    teardown do
      FileUtils.rm_rf Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures')
      FileUtils.rm_rf Ekylibre::Tenant.private_directory.join('prior_to_closure_dump')
    end


    test 'close' do
      Preference.set!(:currency, :FRF)
      f = FinancialYear.where('stopped_on < ?', Date.today).order(:started_on).reject { |f| f.closed? }.first
      # FIXME: Test is not well written. Cheating...
      journal_entries = f.journal_entries.where(state: :draft)
      ValidateDraftJournalEntriesService.new(journal_entries).validate_all if journal_entries.any?

      assert f.closable?, "Financial year #{f.code} should be closable: " + f.closure_obstructions.to_sentence

      options = {
        allocations: {},
        forward_journal: Journal.find_by(nature: :forward, currency: f.currency) ||
          Journal.create_one!(:forward, f.currency),
        closure_journal: Journal.find_by(nature: :closure, currency: f.currency) ||
          Journal.create_one!(:closure, f.currency),
        result_journal: Journal.find_by(nature: :result, currency: f.currency) ||
          Journal.create_one!(:result, f.currency)
      }

      closer = FinancialYearClose.for_year(f, user: User.first, close_on: nil, **options)
      close_result = closer.execute
      assert close_result, "Financial year #{f.code} should be closed (#{f.errors.messages.values.join ', '})"

      assert f.prior_to_closure_archive.present?
      assert f.post_closure_archive.present?

      assert File.exist? f.prior_to_closure_archive.path
      assert File.exist? f.post_closure_archive.path

      assert File.exist? f.prior_to_closure_archive.path.gsub(/zip/, 'asc')
      assert File.exist? f.post_closure_archive.path.gsub(/zip/, 'asc')

      crypto = GPGME::Crypto.new
      assert_equal crypto.verify(f.prior_to_closure_archive.signature) { |s| s.valid? }.class, GPGME::Data
      assert_equal crypto.verify(f.post_closure_archive.signature) { |s| s.valid? }.class, GPGME::Data

      assert File.exist? Ekylibre::Tenant.private_directory.join('prior_to_closure_dump', "#{Ekylibre::Tenant.current}.zip")
    end
  end
end
