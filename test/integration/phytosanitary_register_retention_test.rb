require 'test_helper'

class PhytosanitaryRegisterRetentionTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @document = PhytosanitaryRegisterArchiveJob.perform_now(year: 2020, format: 'xml')
  end

  test 'archive sets sha256_fingerprint' do
    assert_match(/\A[0-9a-f]{64}\z/, @document.sha256_fingerprint.to_s)
  end

  test 'archive sets legal_retention_until at least 5 years out' do
    assert @document.legal_retention_until.present?
    assert @document.legal_retention_until >= Date.current + 5.years
  end

  test 'archive sets mandatory true' do
    assert @document.mandatory
  end

  test 'document is under legal retention immediately after archiving' do
    assert @document.under_legal_retention?
  end

  test 'destroy is blocked while under legal retention' do
    assert_raises(StandardError) do
      @document.destroy!
    end
  end

  test 'destroy succeeds after legal retention expires' do
    @document.update_columns(mandatory: false, legal_retention_until: Date.current - 1.day)
    @document.reload
    assert_nothing_raised do
      @document.destroy!
    end
  end

  test 'sha256_fingerprint matches recomputed digest of archived file' do
    content = File.read(@document.file.path)
    assert_equal Digest::SHA256.hexdigest(content), @document.sha256_fingerprint
  end

  test 'mandatory alone still blocks destroy (existing behavior preserved)' do
    other = Document.create!(name: 'm.txt', mandatory: true, key: 'm', file: File.open(Rails.root.join('Gemfile')))
    assert_raises(StandardError) { other.destroy! }
    other.update_columns(mandatory: false)
    assert_nothing_raised { other.destroy! }
  end

  test 'documents without legal_retention_until are not protected by it' do
    other = Document.create!(name: 'r.txt', key: 'r', file: File.open(Rails.root.join('Gemfile')))
    refute other.under_legal_retention?
    assert_nothing_raised { other.destroy! }
  end
end
