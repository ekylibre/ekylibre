require 'test_helper'

class PhytosanitaryRegisterArchiveJobTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'perform archives a Document with phytosanitary_register nature' do
    assert_difference -> { Document.where(nature: 'phytosanitary_register').count }, 1 do
      PhytosanitaryRegisterArchiveJob.perform_now(year: 2020)
    end
  end

  test 'perform defaults to previous year when year not provided' do
    document = PhytosanitaryRegisterArchiveJob.perform_now
    expected_year = Time.zone.today.year - 1
    assert document.name.include?(expected_year.to_s), "Expected filename to include #{expected_year}, got #{document.name}"
  end

  def read_archived(document)
    File.read(document.file.path)
  end

  test 'perform with xml format produces XML content' do
    document = PhytosanitaryRegisterArchiveJob.perform_now(year: 2020, format: 'xml')
    assert document.name.end_with?('.xml')
    assert_match(/<PhytoRegister[\s>]/, read_archived(document))
  end

  test 'perform with json format produces parseable JSON' do
    document = PhytosanitaryRegisterArchiveJob.perform_now(year: 2020, format: 'json')
    assert document.name.end_with?('.json')
    parsed = JSON.parse(read_archived(document))
    assert parsed.key?('meta')
    assert parsed.key?('entries')
  end

  test 'perform with csv format produces CSV with header row' do
    document = PhytosanitaryRegisterArchiveJob.perform_now(year: 2020, format: 'csv')
    assert document.name.end_with?('.csv')
    rows = CSV.parse(read_archived(document))
    assert_equal Phytosanitary::Register::Entry.members.map(&:to_s), rows.first
  end

  test 'perform with unknown format raises ArgumentError' do
    assert_raises(ArgumentError) do
      PhytosanitaryRegisterArchiveJob.perform_now(year: 2020, format: 'pdf')
    end
  end

  test 'archive document name includes year' do
    document = PhytosanitaryRegisterArchiveJob.perform_now(year: 2019, format: 'xml')
    assert_includes document.name, '2019'
  end
end
