require 'test_helper'
class Backend::DocumentArchivesControllerTest < ActionController::TestCase
  test_restfully_all_actions show: {format: :pdf}

  FILES = {
    document_archives_001: "outgoing_deliveries.pdf",
    document_archives_002: "report.odt"
  }

  setup do
    for id, file in FILES
      archive = document_archives(id)
      old_updated_at = archive.file_updated_at
      archive.file = fixture_file_upload("files/#{file}", "application/#{file.split('.').last}")
      archive.save!
      assert_not_equal old_updated_at, archive.file_updated_at, "File doesn't seems to be updated"
    end
  end

end
