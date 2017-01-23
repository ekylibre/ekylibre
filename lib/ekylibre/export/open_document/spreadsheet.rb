require 'zip'

Mime::Type.register('application/vnd.oasis.opendocument.spreadsheet', :ods) unless defined? Mime::ODS

module Ekylibre
  module Export
    module OpenDocument
      class Spreadsheet
        def initialize
          @header = ''
          zile.put_next_entry('META-INF/manifest.xml')
          zile.puts('<?xml version="1.0" encoding="UTF-8"?><manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"><manifest:file-entry manifest:media-type="' + Mime::ODS + '" manifest:full-path="/"/><manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/><manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml"/></manifest:manifest>')
          zile.put_next_entry('mimetype')
          zile.puts(Mime::ODS)
          zile.put_next_entry('styles.xml')
          zile.puts(File.open(File.join(File.expand_path(File.dirname(__FILE__)), 'spreadsheet', 'styles.xml'), 'rb:UTF-8').read)
          zile.put_next_entry('content.xml')
          zile.puts('<?xml version="1.0" encoding="UTF-8"?><office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:field="urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:field:1.0" office:version="1.1"><office:scripts/>')
          zile.puts('<office:automatic-styles>' + # "<style:style style:name=\"co1\" style:family=\"table-column\"><style:table-column-properties fo:break-before=\"auto\" style:use-optimal-column-width=\"true\"/></style:style>"+
                    "<style:style style:name=\"header\" style:family=\"table-cell\"><style:text-properties fo:font-size=\"#{font_size}pt\" style:font-size-asian=\"#{font_size}pt\" style:font-size-complex=\"#{font_size}pt\" fo:font-weight=\"bold\" style:font-weight-asian=\"bold\" style:font-weight-complex=\"bold\"/><style:table-cell-properties fo:border=\"0.002cm solid #000000\"/></style:style>"\
                    "<style:style style:name=\"ce1\" style:family=\"table-cell\"><style:text-properties fo:font-size=\"#{font_size}pt\" style:font-size-asian=\"#{font_size}pt\" style:font-size-complex=\"#{font_size}pt\"/><style:table-cell-properties fo:border=\"0.002cm solid #000000\"/></style:style>" + #  fo:wrap-option=\"wrap\"
                    "<style:style style:name=\"ce2\" style:family=\"table-cell\"><style:text-properties fo:font-size=\"#{font_size}pt\" style:font-size-asian=\"#{font_size}pt\" style:font-size-complex=\"#{font_size}pt\"/><style:table-cell-properties style:text-align-source=\"fix\" style:repeat-content=\"false\" fo:border=\"0.002cm solid #000000\"/><style:paragraph-properties fo:text-align=\"center\" fo:margin-left=\"0cm\"/></style:style>"\
                    '<style:style style:name="ta1" style:family="table" style:master-page-name="Default"><style:table-properties table:display="true" style:writing-mode="lr-tb"/></style:style>'\
                    "<style:style style:name=\"ro1\" style:family=\"table-row\"><style:table-row-properties style:row-height=\"#{height}cm\" fo:break-before=\"auto\" style:use-optimal-row-height=\"false\"/></style:style>"\
                    "<style:style style:name=\"ro2\" style:family=\"table-row\"><style:table-row-properties style:row-height=\"#{height}cm\" fo:break-before=\"page\" style:use-optimal-row-height=\"false\"/></style:style>" + # "<number:date-style style:name=\"K4D\" number:automatic-order=\"true\"><number:text>"+::I18n.translate("date.formats.default").gsub(/\%./){|x| "</number:text>"+DATE_ELEMENTS[x[1..1]]+"<number:text>"} +"</number:text></number:date-style><style:style style:name=\"ce1\" style:family=\"table-cell\" style:data-style-name=\"K4D\"/>"+
                    query.columns.collect do |column|
                      "<style:style style:name=\"co#{column[:index]}\" style:family=\"table-column\"><style:table-column-properties fo:break-before=\"auto\" style:column-width=\"#{column[:size] * cmpc + fixed_margin}cm\"/></style:style>"
                    end.join + '</office:automatic-styles>')

          # Tables
          zile.puts('<office:body><office:spreadsheet>')
          yield zile if block_given?
          zile.puts('</office:spreadsheet></office:body></office:document-content>')
        end

        def header(&_block); end

        def generate(output)
          start = Time.zone.now
          Zip::OutputStream.open(output + '.ods') do |_zile|
          end
        end

        def self.generate(output, options = {}, &_block)
          document = new
          yield document
          document.generate(output, options)
        end
      end
    end
  end
end

ods.generate do |d|
  d.header do |h|
    h
  end
end
