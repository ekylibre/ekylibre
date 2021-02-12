module FinancialYearExchanges
  class FecXmlExport
    def generate_file(exchange)
      financial_year = exchange.financial_year
      fiscal_position = financial_year.fec_format
      started_on = exchange.started_on
      stopped_on = exchange.stopped_on
      datas = FEC::Exporter::XML.new(financial_year, fiscal_position, started_on, stopped_on).generate
      Tempfile.open do |tempfile|
        tempfile.write(datas)
        tempfile.close
        yield tempfile
      end
    end

    def filename(exchange)
      siren = Entity.of_company.siret_number.present? ? Entity.of_company.siren_number : ''
      stopped_on = exchange.financial_year.stopped_on.l(format: '%Y%m%d')
      "#{siren}FEC#{stopped_on}.xml"
    end
  end
end
