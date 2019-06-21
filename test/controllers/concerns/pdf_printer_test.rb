require 'test_helper'

class PdfPrinterTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @klass = Class.new do
      include PdfPrinter
    end
    @subject = @klass.new
  end

  test 'it generates PDF report data' do
    data = @subject.generate_report(fixture_file('pdf_printer_1.odt')) do |r|
      r.add_field 'FILE_NAME', 'My file name'
    end
    generated = read_pdf_data(data)
    expected = read_pdf_data(File.read(fixture_file('pdf_printer_1_expected.pdf')))
    compare_pdfs expected, generated
  end

  test 'it generates PDF report file' do
    path = @subject.generate_report_file(fixture_file('pdf_printer_1.odt')) do |r|
      r.add_field 'FILE_NAME', 'My file name'
    end
    generated = read_pdf_data(File.read(path))
    expected = read_pdf_data(File.read(fixture_file('pdf_printer_1_expected.pdf')))
    compare_pdfs expected, generated
  end

  test 'it archives a report from a file' do
    file = File.open(fixture_file('pdf_printer_1.odt'))
    document_nature = Nomen::DocumentNature.find(:balance_sheet)
    document = @subject.archive_report(document_nature, 'pdf-test', file)
    assert document.is_a?(Document)
    assert_equal 'balance_sheet', document.nature
    assert_equal 'pdf-test', document.key
    assert_equal I18n.translate('models.document_template.document_name', nature: document_nature.human_name, key: 'pdf-test'), document.name
    assert_equal file.read, File.read(document.file.path)
  end

  test 'it archives a report from data' do
    data = File.read(fixture_file('pdf_printer_1.odt'))
    document_nature = Nomen::DocumentNature.find(:balance_sheet)
    document = @subject.archive_report(document_nature, 'pdf-test', data)
    assert document.is_a?(Document)
    assert_equal 'balance_sheet', document.nature
    assert_equal 'pdf-test', document.key
    assert_equal I18n.translate('models.document_template.document_name', nature: document_nature.human_name, key: 'pdf-test'), document.name
    assert_equal data, File.read(document.file.path)
  end

  test 'it generates a document' do
    source = fixture_file('pdf_printer_1.odt')
    document_nature = Nomen::DocumentNature.find(:balance_sheet)
    document = @subject.generate_document(document_nature, 'pdf-test', source) do |r|
      r.add_field 'FILE_NAME', 'My file name'
    end
    assert document.is_a?(Document)
    assert_equal 'balance_sheet', document.nature
    assert_equal 'pdf-test', document.key
    assert_equal I18n.translate('models.document_template.document_name', nature: document_nature.human_name, key: 'pdf-test'), document.name
    expected = read_pdf_data(File.read(fixture_file('pdf_printer_1_expected.pdf')))
    compare_pdfs expected, read_pdf_data(File.read(document.file.path))
  end

  def read_pdf_data(data)
    io = StringIO.new(data)
    PDF::Reader.new io
  end

  def compare_pdfs(pdf1, pdf2)
    assert_equal pdf1.page_count, pdf2.page_count
    pdf1.page_count.times do |page_index|
      assert_equal pdf1.pages[page_index].raw_content, pdf2.pages[page_index].raw_content
    end
  end
end
