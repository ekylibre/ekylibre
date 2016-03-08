require 'nokogiri'

module Charta
  class KmlImport
    def initialize(data)
      @shapes = nil
      @xml = data
    end

    def sanitize(xml)
      xml.to_s.squish
    end

    def shapes(options = {})
      options[:to] ||= ''

      f = sanitize @xml

      doc = Nokogiri::XML(f) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS
      end

      @shapes = doc.css('Polygon')

      if options[:to].equal? :xml
        @shapes = @shapes.to_xml
      elsif options[:to].equal? :string
        @shapes = @shapes.to_s
      else
        @shapes
      end
    end
  end
end
