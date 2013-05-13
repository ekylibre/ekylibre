module Nomenclature

  DocumentNature = Struct.new(:name, :categories, :datasource)

  class DocumentClassification < Base

    # Returns a array of all known document natures
    def self.document_natures
      @@document_natures ||= @@document.xpath('/document-classification/document-natures/document-nature').collect do |node|
        DocumentNature.new(node.attr("name"),
                           node.attr("categories").split(/[\s\,]+/).map(&:to_sym),
                           node.attr("datasource"))
      end
    end

  end


end
