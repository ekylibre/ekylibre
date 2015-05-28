module Charta
  # Represents a Geometry with SRID
  class Geometry

    attr_reader :ewkt

    def initialize(coordinates, srs = nil)
      if coordinates.nil?
        @ewkt = self.class.empty(srs).to_ewkt
      elsif coordinates.is_a?(self.class)
        @ewkt = coordinates.ewkt
      elsif coordinates.is_a?(Hash) or (coordinates.is_a?(String) and ::Charta::GeoJSON.valid?(coordinates)) # GeoJSON
        srid = srs ? find_srid(srs) : :WGS84
        @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKT('#{::Charta::GeoJSON.new(coordinates, srid).to_ewkt}'))")
      elsif coordinates.is_a?(String)
        if coordinates =~ /\A[A-F0-9]+\z/ # WKB
          if srs and srid = find_srid(srs)
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText(E'\\\\x#{coordinates}', #{srid}))")
          else
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKB(E'\\\\x#{coordinates}'))")
          end
        else # WKT expected
          if srs and srid = find_srid(srs)
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates}', #{srid}))")
          else
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKT('#{coordinates}'))")
          end
        end
      else
        @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates.as_text}', #{coordinates.srid}))")
      end
      if @ewkt.blank?
        raise ArgumentError, "Invalid data: coordinates=#{coordinates.inspect}, srid=#{srid.inspect}"
      end
    end

    def inspect
      "<Geometry(#{@ewkt})>"
    end

    def geom
      "ST_MakeValid(ST_GeomFromEWKT('#{@ewkt}'))"
    end

    def srid
      return select_value("SELECT ST_SRID(#{self.geom})").to_i
    end

    def to_rgeo
      @ewkt
    end

    def to_text
      return select_value("SELECT ST_AsText(#{self.geom})")
    end
    alias :as_text :to_text

    def to_ewkt
      return @ewkt
    end

    def to_binary
      return select_value("SELECT ST_AsEWKB(#{self.geom})")
    end

    def to_gml
      return select_value("SELECT ST_AsGML(#{self.geom})")
    end

    def to_kml
      return select_value("SELECT ST_AsKML(#{self.geom})")
    end

    def to_svg(options = {})
      svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\""
      for attr, value in {preserve_aspect_ratio: 'xMidYMid meet', width: 180, height: 180, view_box: self.bounding_box.svg_view_box.join(' ')}.merge(options)
        svg << " #{attr.to_s.camelcase(:lower)}=\"#{value}\""
      end
      svg << "><path d=\"#{self.to_svg_path}\"/></svg>"
      return svg
    end

    def to_svg_path
      return select_value("SELECT ST_AsSVG(#{self.geom})")
    end

    def to_geojson
      return JSON.parse(select_value("SELECT ST_AsGeoJSON(#{self.geom})"))
    end


    # Test if the other measure is equal to self
    def ==(other_geometry)
      other = self.class.new(other_geometry).transform(self.srid)
      return select_value("SELECT ST_Equals(#{self.geom}, #{other.geom})") =~ /\At(rue)?\z/
    end

    # Test if the other measure is equal to self
    def !=(other_geometry)
      other = self.class.new(other_geometry).transform(self.srid)
      return select_value("SELECT NOT ST_Equals(#{self.geom}, #{other.geom})") =~ /\At(rue)?\z/
    end


    # Returns area in square meter
    def area
      if srid = find_srid(Preference[:map_measure_srs])
        value = select_value("SELECT ST_Area(ST_Transform(#{self.geom}, #{srid}))")
      else
        value = select_value("SELECT ST_Area(#{self.geom}::geography)")
      end
      return (value.blank? ? 0.0 : value.to_d).in_square_meter
    end

    def empty?
      return select_value("SELECT ST_IsEmpty(#{self.geom})") =~ /\At(rue)?\z/
    end

    def centroid
      return select_row("SELECT ST_Y(ST_Centroid(#{self.geom})), ST_X(ST_Centroid(#{self.geom}))").map(&:to_f)
    end

    def point_on_surface
      return select_row("SELECT ST_Y(ST_PointOnSurface(#{self.geom})), ST_X(ST_PointOnSurface(#{self.geom}))").map(&:to_f)
    end

    def transform(srid)
      return self.class.new(select_value("SELECT ST_AsEWKT(ST_Transform(#{self.geom}, #{find_srid(srid)}))"))
    end

    def multi_polygon
      return self.class.new(select_value("SELECT ST_AsEWKT(ST_Multi(ST_CollectionExtract(ST_CollectionHomogenize(ST_Multi(#{self.geom})), 3)))"))
    end

    def circle(radius)
      return self.class.new(select_value("SELECT ST_Buffer(#{self.geom}, #{radius})"))
    end


    # def merge!(other_geometry)
    #   @ewkt = self.merge(other_geometry).ewkt
    # end

    def actors_matching(options = {})
      operator = '~'
      operator = '&&' if options[:intersection]
      options[:nature] ||= Product
      actors_id = ProductReading.
        where("geometry_value #{operator} #{self.geom}").pluck(:product_id)
      return Product.find(actors_id).
        delete_if{|actor| !actor.is_a?(options[:nature]) || actor == self}.
        flatten
    end

    def merge(other_geometry)
      other = self.class.new(other_geometry).transform(self.srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Union(#{self.geom}, #{other.geom}))"))
    end

    def intersection(other_geometry)
      other = self.class.new(other_geometry).transform(self.srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Multi(ST_CollectionExtract(ST_CollectionHomogenize(ST_Multi(ST_Intersection(#{self.geom}, #{other.geom}))), 3)))"))
    end

    def bounding_box
      unless @bounding_box
        values = select_row("SELECT " + [:YMin, :XMin, :YMax, :XMax].collect do |v|
                              "ST_#{v}(#{self.geom})"
                            end.join(", ")).map(&:to_f)
        [:y_min, :x_min, :y_max, :x_max].each_with_index do |val, index|
          self.instance_variable_set("@#{val}", values[index])
        end
        @bounding_box = BoundingBox.new(*values)
      end
      return @bounding_box
    end

    def x_min
      bounding_box.x_min
    end

    def y_min
      bounding_box.y_min
    end

    def x_max
      bounding_box.x_max
    end

    def y_max
      bounding_box.y_max
    end

    def select_value(query)
      self.class.select_value(query)
    end

    def select_row(query)
      self.class.select_row(query)
    end

    def find_srid(name_or_srid)
      self.class.find_srid(name_or_srid)
    end



    class << self

      # Link to the nomenclature
      def systems
        Nomen::SpatialReferenceSystems
      end

      def empty(srid = :WGS84)
        new("MULTIPOLYGON EMPTY", srid)
      end

      # # Converts coordinates of a Geometry into the reference of the given SRID
      # def transform(geometry, srid)
      #   geometry = new(geometry)
      #   return new(select_value("SELECT ST_Transform(#{geometry.geom}, #{find_srid(srid)})"))
      # end

      # Execute a query
      def select_value(query)
        ActiveRecord::Base.connection.select_value(query)
      end

      # Execute a query
      def select_row(query)
        ActiveRecord::Base.connection.select_rows(query).first
      end

      # Check and returns the SRID matching with srname or SRID.
      def find_srid(srname_or_srid)
        if srname_or_srid.is_a?(Symbol) or srname_or_srid.is_a?(String)
          item = systems.items[srname_or_srid]
        else
          item = systems.find_by(srid: srname_or_srid)
        end
        return (item ? item.srid : nil)
      end

    end

  end
end
