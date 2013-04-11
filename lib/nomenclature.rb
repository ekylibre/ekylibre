module Nomenclature

  class NomenclatureDocumentNotFoundError < StandardError
  end

  # Manage all nomenclature
  class Base

    # Load the corresponding XML document once for all
    def self.inherited(subclass)
      subpath = subclass.name.underscore.dasherize.split('/')[1..-1]
      subpath[-1] += ".xml"
      document = Rails.root.join("config", "nomenclatures", *subpath)
      unless document.exist?
        raise NomenclatureDocumentNotFoundError.new("File #{document} not found for #{subclass.name} nomenclature")
      end
      f = File.open(document, "rb")
      @@document = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks.noent
      end
      f.close
    end

  end

  autoload :DocumentClassification, 'nomenclature/document_classification'


end


