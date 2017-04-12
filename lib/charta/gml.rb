module Charta
  # Represents a Geometry with SRID
  class GML
    attr_reader :srid

    TAGS = %w[Point LineString Polygon MultiGeometry].freeze
    OGR_PREFIX = 'ogr'.freeze
    GML_PREFIX = 'gml'.freeze
    NS = {
      gml: 'http://www.opengis.net/gml',
      ogr: 'http://ogr.maptools.org/'
    }.freeze

    def initialize(data, srid = :WGS84)
      srid ||= :WGS84
      @gml = if data.is_a? String

               Nokogiri::XML(data.to_s.squish) do |config|
                 config.options = Nokogiri::XML::ParseOptions::NOBLANKS
               end

             else
               # Nokogiri::XML::Document expected
               data
             end
      up = false
      # ensure namespaces are defined
      begin
        @gml.root.add_namespace_definition('xmlns', '')
        NS.each do |k, v|
          if @gml.xpath("//@*[xmlns:#{k}]").empty?
            @gml.root.namespace_definitions << @gml.root.add_namespace_definition(k.to_s, v)
            up = true
          end
        end
      rescue
        false
      end

      @gml = Nokogiri::XML(@gml.to_xml) if up

      boundaries = @gml.css("#{GML_PREFIX}|boundedBy")
      if boundaries.present?
        boundaries.each do |node|
          srid = Charta.find_srid(node['srsName']) unless node['srsName'].nil?
        end
      end

      @srid = Charta.find_srid(srid)
    end

    def to_ewkt
      "SRID=#{@srid};" + self.class.document_to_ewkt(@gml, @srid)
    end

    def valid?
      to_ewkt
      true
    rescue
      false
    end

    class << self
      # Test is given data is a valid GML
      def valid?(data, srid = :WGS84)
        new(data, srid).valid?
      rescue
        false
      end

      def object_to_ewkt(fragment, srid)
        send("#{fragment.name.snakecase}_to_ewkt", fragment, srid)
      end

      def document_to_ewkt(gml, srid)
        # whole document
        if gml.css("#{OGR_PREFIX}|FeatureCollection").blank? || gml.css("#{GML_PREFIX}|featureMember").blank?
          # fragment
          if gml.root.name && TAGS.include?(gml.root.name)
            object_to_ewkt(gml.root, srid)
          else
            'GEOMETRYCOLLECTION EMPTY'
          end
        else
          'GEOMETRYCOLLECTION(' + gml.css("#{GML_PREFIX}|featureMember").collect do |feature|
            TAGS.collect do |tag|
              next if feature.css("#{GML_PREFIX}|#{tag}").empty?
              feature.css("#{GML_PREFIX}|#{tag}").collect do |fragment|
                object_to_ewkt(fragment, srid)
              end.compact.join(', ')
            end.compact.join(', ')
          end.compact.join(', ') + ')'
        end
      end
      alias geometry_collection_to_ewkt document_to_ewkt

      def transform(data, from_srid, to_srid)
        Charta.select_value("SELECT ST_AsText(ST_Transform(ST_GeomFromText('#{data}', #{from_srid}),#{to_srid}))")
      end

      def polygon_to_ewkt(gml, srid)
        return 'POLYGON EMPTY' if gml.css("#{GML_PREFIX}|coordinates").blank?

        wkt = 'POLYGON(' + %w[outerBoundaryIs innerBoundaryIs].collect do |boundary|
          next if gml.css("#{GML_PREFIX}|#{boundary}").empty?
          gml.css("#{GML_PREFIX}|#{boundary}").collect do |hole|
            '(' + hole.css("#{GML_PREFIX}|coordinates").collect { |coords| coords.content.split(/\r\n|\n| /) }.flatten.reject(&:empty?).collect { |c| c.split ',' }.collect { |dimension| %(#{dimension.first} #{dimension.second}) }.join(', ') + ')'
          end.join(', ')
        end.compact.join(', ') + ')'

        unless gml['srsName'].nil? || Charta.find_srid(gml['srsName']).to_s == srid.to_s
          wkt = transform(wkt, Charta.find_srid(gml['srsName']), srid)
        end

        wkt
      end

      def point_to_ewkt(gml, srid)
        return 'POINT EMPTY' if gml.css("#{GML_PREFIX}|coordinates").blank?
        wkt = 'POINT(' + gml.css("#{GML_PREFIX}|coordinates").collect { |coords| coords.content.split ',' }.flatten.join(' ') + ')'

        unless gml['srsName'].nil? || Charta.find_srid(gml['srsName']).to_s == srid.to_s
          wkt = transform(wkt, Charta.find_srid(gml['srsName']), srid)
        end

        wkt
      end

      def line_string_to_ewkt(gml, srid)
        return 'LINESTRING EMPTY' if gml.css("#{GML_PREFIX}|coordinates").blank?

        wkt = 'LINESTRING(' + gml.css("#{GML_PREFIX}|coordinates").collect { |coords| coords.content.split(/\r\n|\n| /) }.flatten.reject(&:empty?).collect { |c| c.split ',' }.collect { |dimension| %(#{dimension.first} #{dimension.second}) }.join(', ') + ')'

        unless gml['srsName'].nil? || Charta.find_srid(gml['srsName']).to_s == srid.to_s
          wkt = transform(wkt, Charta.find_srid(gml['srsName']), srid)
        end

        wkt
      end
    end
  end
end
