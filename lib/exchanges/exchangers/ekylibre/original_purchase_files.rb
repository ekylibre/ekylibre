# Create or updates purchases
Exchanges.add_importer :ekylibre_original_purchase_files do |file, w|

  dir = w.tmp_dir
  Zip::File.open(file) do |zile|
    w.count = zile.entries.size
    zile.each do |entry|
      e = entry.extract(dir.join(entry.name))
      # set parameter
      path = dir.join(entry.name)
      arr = e.name.strip.split('_')
      ar = arr[2].split('.')
      reference_number = ar[0].upcase
      extension = ar[1]
      key = e.time.to_s(:number) + "-" + e.size.to_s + "-" + reference_number

      # TODO add a method to detect before importing the same key in order to avoid bad validation on key
      # create document
      if path and extension and e.name and key
        document = Document.create!(key: key, name: e.name, nature: "purchases_original")
        document.archive(path, extension.to_sym)
      else
        raise StandardError, "Problem on #{e.name} purchase document"
      end

      # get purchase and link with document
      purchase = Purchase.where(reference_number: reference_number).first
      purchase.attachments.create!(document: document) if document and purchase
    end
    w.check_point
  end
end
