require 'test_helper'
class Backend::DocumentArchivesControllerTest < ActionController::TestCase
  test_restfully_all_actions

  def setup
    super
    for id in %w(001 002)
      archive = document_archives("document_archives_#{id}".to_sym)
      if archive.valid?
        assert archive.file.file?
      else
        archive.file = fixture_file_upload("files/outgoing_deliveries.pdf", "application/pdf")
        assert archive.save
      end
    end
  end

end
