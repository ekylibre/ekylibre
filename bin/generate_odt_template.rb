#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates a minimal but valid ODF text template for ODFReport.
#
# These templates are deliberately plain: they carry the right placeholders,
# named tables and sections so the matching Printers::* class works, and no
# visual design at all. They are meant to be reopened in LibreOffice and
# styled — the markup below is what ODFReport binds to, and must be preserved:
#
#   * a scalar field is the literal text `[FIELD_NAME]`
#   * a repeated block is a table whose `table:name` matches `add_table`
#   * the first row of such a table is the header, the second carries the
#     `[COLUMN]` placeholders and is duplicated per record
#
# Usage:
#   bin/generate_odt_template.rb <destination.odt> <spec.json>
#
# Spec format:
#   { "title": "...", "fields": ["A", "B"],
#     "tables": [{ "name": "ITEMS", "columns": ["X", "Y"], "headers": ["X", "Y"] }] }

require 'json'
require 'zip'

MIMETYPE = 'application/vnd.oasis.opendocument.text'

def esc(str)
  str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
end

def paragraph(text, style: 'Standard')
  %(<text:p text:style-name="#{style}">#{esc(text)}</text:p>)
end

def table_xml(spec)
  name = spec.fetch('name')
  columns = spec.fetch('columns')
  headers = spec['headers'] || columns
  cells = lambda do |values, style|
    values.map { |v| %(<table:table-cell office:value-type="string">#{paragraph(v, style: style)}</table:table-cell>) }.join
  end

  <<~XML
    <table:table table:name="#{esc(name)}" table:style-name="TableGrid">
      <table:table-column table:number-columns-repeated="#{columns.size}"/>
      <table:table-header-rows>
        <table:table-row>#{cells.call(headers, 'TableHead')}</table:table-row>
      </table:table-header-rows>
      <table:table-row>#{cells.call(columns.map { |c| "[#{c.to_s.upcase}]" }, 'Standard')}</table:table-row>
    </table:table>
  XML
end

def content_xml(spec)
  body = []
  body << paragraph('[DOCUMENT_NAME]', style: 'Title')
  spec.fetch('fields', []).each { |f| body << paragraph("#{f.to_s.tr('_', ' ').capitalize} : [#{f.to_s.upcase}]") }
  spec.fetch('tables', []).each do |t|
    body << paragraph('')
    body << table_xml(t)
  end
  body << paragraph('')

  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <office:document-content
      xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
      xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
      xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
      xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
      xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
      office:version="1.2">
      <office:automatic-styles/>
      <office:body>
        <office:text>
          #{body.join("\n          ")}
        </office:text>
      </office:body>
    </office:document-content>
  XML
end

STYLES_XML = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <office:document-styles
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    office:version="1.2">
    <office:styles>
      <style:style style:name="Standard" style:family="paragraph"/>
      <style:style style:name="Title" style:family="paragraph" style:parent-style-name="Standard">
        <style:text-properties fo:font-size="16pt" fo:font-weight="bold"/>
      </style:style>
      <style:style style:name="TableHead" style:family="paragraph" style:parent-style-name="Standard">
        <style:text-properties fo:font-weight="bold"/>
      </style:style>
      <style:style style:name="TableGrid" style:family="table"/>
    </office:styles>
  </office:document-styles>
XML

MANIFEST_XML = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">
    <manifest:file-entry manifest:full-path="/" manifest:media-type="#{MIMETYPE}"/>
    <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
    <manifest:file-entry manifest:full-path="styles.xml" manifest:media-type="text/xml"/>
    <manifest:file-entry manifest:full-path="meta.xml" manifest:media-type="text/xml"/>
  </manifest:manifest>
XML

def meta_xml(title)
  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <office:document-meta
      xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      office:version="1.2">
      <office:meta><dc:title>#{esc(title)}</dc:title></office:meta>
    </office:document-meta>
  XML
end

destination, spec_path = ARGV
abort "usage: #{$PROGRAM_NAME} <destination.odt> <spec.json>" unless destination && spec_path
spec = JSON.parse(File.read(spec_path))

File.delete(destination) if File.exist?(destination)
Zip::OutputStream.open(destination) do |zos|
  # ODF requires `mimetype` to be the first entry AND stored uncompressed:
  # that is what makes the file recognisable by magic bytes. MimeMagic (used by
  # Printers::MimeTypeGuesser, itself used by DocumentTemplate to decide between
  # the ODT and the Jasper path) returns nothing otherwise, and the template is
  # then parsed as Jasper XML.
  zos.put_next_entry('mimetype', nil, nil, Zip::Entry::STORED)
  zos.write MIMETYPE

  { 'META-INF/manifest.xml' => MANIFEST_XML,
    'content.xml' => content_xml(spec),
    'styles.xml' => STYLES_XML,
    'meta.xml' => meta_xml(spec['title']) }.each do |name, payload|
    zos.put_next_entry(name)
    zos.write payload
  end
end
puts "#{destination} (#{File.size(destination)} o)"
