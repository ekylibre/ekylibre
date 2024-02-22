namespace :help_doc do
  desc "Generate PDF file from all helps files in Markdown with locale"
  task pdf: :environment do
    locale = ENV['LOCALE'] || 'fra'
    help_dir = Rails.root.join('config', 'locales', locale, 'help')
    help_dir_filter = help_dir.join('*.md')
    # check folder
    destination = Rails.root.join('doc', 'help_doc', locale)
    pdf_destination = Rails.root.join('doc', 'help_doc', "#{locale}.pdf")
    FileUtils.mkdir_p(destination)
    final_pdf = CombinePDF.new
    # generate on PDF file for each help file
    Dir.glob(help_dir_filter) do |filename|
      doc_filename = filename.split('/').last + '.pdf'
      content = nil
      File.open(filename, 'rb:UTF-8') { |f| content = f.read }
      # convert md to pdf
      file_content = KramdownToHtmlService.pdf(content: content)
      # generate on file
      pdf_path = destination.join(doc_filename)
      File.binwrite(pdf_path, file_content)
      final_pdf << CombinePDF.load(pdf_path, allow_optional_content: true)
    end
    # create final pdf object
    final_pdf.save(pdf_destination)
    # remove tmp pdf files
    FileUtils.rm_rf(destination)
  end
end
