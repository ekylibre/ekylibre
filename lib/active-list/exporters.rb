# require 'active_support/core_ext/module/attribute_accessors'
module ActiveList

  module Exporters

    def self.hash
      ActiveList.exporters
    end

    autoload :AbstractExporter,                'active-list/exporters/abstract_exporter'
    autoload :OpenDocumentSpreadsheetExporter, 'active-list/exporters/open_document_spreadsheet_exporter'
    autoload :CsvExporter,                     'active-list/exporters/csv_exporter'
    autoload :ExcelCsvExporter,                'active-list/exporters/excel_csv_exporter'
  end

  mattr_reader :exporters
  @@exporters = {}

  def self.register_exporter(name, exporter)
    raise ArgumentError.new("ActiveList::Exporters::AbstractExporter expected (got #{exporter.name}/#{exporter.ancestors.inspect})") unless exporter < ActiveList::Exporters::AbstractExporter
    @@exporters[name] = exporter
  end

end

ActiveList.register_exporter(:ods,  ActiveList::Exporters::OpenDocumentSpreadsheetExporter)
ActiveList.register_exporter(:csv,  ActiveList::Exporters::CsvExporter)
ActiveList.register_exporter(:xcsv, ActiveList::Exporters::ExcelCsvExporter)
