module PdfPrinter
  extend ActiveSupport::Concern

  # return data
  def generate_report(template_name_or_path, &block)
    template_path = to_template_path(template_name_or_path)
    report = ODFReport::Report.new(template_path, &block)
    to_pdf_data report
  end
  
  # return file
  def generate_report_file(template_name_or_path, &block)
    template_path = to_template_path(template_name_or_path)
    data = generate_report template_path, &block
    file = Tempfile.new(['source', '.pdf'])
    begin
      file.write data
      file.path
    ensure
      file.close
    end
  end
  
  # return file and store file in documents
  def generate_document(nature, key, template_name_or_path, options = { archiving: :last }, &block)
    data = generate_report(template_name_or_path, &block)
    archive_report nature, key, data, options
  end
  
  # store file in document
  def archive_report(nature, key, data_or_path, options = { archiving: :last })
    data = data_or_path.kind_of?(File) ? data_or_path : StringIO.new(data_or_path)
    name = options[:name] || I18n.translate('models.document_template.document_name', nature: nature, key: key)
    Document.create!(
      nature: nature,
      key: key,
      name: name,
      file: data
    )
  end

  private

  def to_template_path(name_or_path)
    return name_or_path unless name_or_path.kind_of?(String)
    directory = self.class.name.gsub(/Printer$/, '').underscore
    file_name = "#{name_or_path}.odt"
    Rails.root.join('config', 'locales', I18n.locale.to_s, 'reporting', directory, file_name)
  end

  def to_pdf_data(report)
    Dir.mktmpdir do |directory|
      directory_path = Pathname.new(directory)
      odf_path = directory_path.join('source.odf').to_s
      report.generate odf_path
      system "soffice --headless --convert-to pdf --outdir #{directory} #{odf_path}"
      pdf_path = directory_path.join('source.pdf').to_s
      File.read pdf_path
    end
  end

end
