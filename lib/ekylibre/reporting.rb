module Ekylibre
  module Reporting
    FORMATS = %w[pdf odt ods docx xlsx].freeze

    # Returns the list of formats used by default for the reporting.
    # The default format is the first.
    def self.formats
      FORMATS
    end
  end
end
