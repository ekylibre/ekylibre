module Charta
  # Represents a Geometry with SRID
  class Geometry
    attr_reader :ewkt

    def initialize(ewkt)
      @ewkt = ewkt
      fail ArgumentError, 'Need EWKT to instantiate Geometry' if @ewkt.blank?
    end

    def inspect
      "<Geometry(#{@ewkt})>"
    end

    def geom
      "ST_MakeValid(ST_GeomFromEWKT('#{@ewkt}'))"
    end

    def type
      select_value("SELECT GeometryType(#{geom})").to_s.strip
    end

    def collection?
      select_value("SELECT ST_GeometryType(#{geom})") =~ /\AST_GeometryCollection\z/
    end

    def srid
      select_value("SELECT ST_SRID(#{geom})").to_i
    end

    def srid=(srid)
      @ewkt = select_value("SELECT ST_AsEWKT(ST_SetSRID(#{geom}, #{srid}))")
    end

    def to_rgeo
      to_ewkt
    end

    def to_text
      select_value("SELECT ST_AsText(#{geom})")
    end
    alias as_text to_text

    def to_ewkt
      @ewkt.to_s
    end

    def to_s
      @ewkt.to_s
    end

    def to_binary
      select_value("SELECT ST_AsEWKB(#{geom})")
    end

    def to_gml
      select_value("SELECT ST_AsGML(#{geom})")
    end

    def to_kml
      select_value("SELECT ST_AsKML(#{geom})")
    end

    def to_svg(options = {})
      svg = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1"'
      for attr, value in { preserve_aspect_ratio: 'xMidYMid meet', width: 180, height: 180, view_box: bounding_box.svg_view_box.join(' ') }.merge(options)
        svg << " #{attr.to_s.camelcase(:lower)}=\"#{value}\""
      end
      svg << "><path d=\"#{to_svg_path}\"/></svg>"
      svg
    end

    def to_svg_path
      select_value("SELECT ST_AsSVG(#{geom})")
    end

    def to_geojson
      select_value("SELECT ST_AsGeoJSON(#{geom})")
    end
    alias to_json to_geojson

    def to_json_object
      JSON.parse(to_json)
    end

    # Test if the other measure is equal to self
    def ==(other_geometry)
      other = Charta.new_geometry(other_geometry).transform(srid)
      return true if empty? && other.empty?
      # fail 'Cannot compare geometry collection' if collection? && other.collection?
      return false if collection? && other.collection?
      select_value("SELECT ST_Equals(#{geom}, #{other.geom})") =~ /\At(rue)?\z/
    end

    # Test if the other measure is equal to self
    def !=(other_geometry)
      other = Charta.new_geometry(other_geometry).transform(srid)
      if collection? && other.collection?
        return true if (empty? && !other.empty?) || (!empty? && other.empty?)
        # fail 'Cannot compare geometry collection'
        return false
      end
      select_value("SELECT NOT ST_Equals(#{geom}, #{other.geom})") =~ /\At(rue)?\z/
    end

    # Returns area in square meter
    def area
      value = if srid = find_srid(Preference[:map_measure_srs])
                select_value("SELECT ST_Area(ST_Transform(#{geom}, #{srid}))")
              else
                select_value("SELECT ST_Area(#{geom}::geography)")
              end
      (value.blank? ? 0.0 : value.to_d).in_square_meter
    end

    def empty?
      select_value("SELECT ST_IsEmpty(#{geom})") =~ /\At(rue)?\z/
    end
    alias blank? empty?

    def centroid
      select_row("SELECT ST_Y(ST_Centroid(#{geom})), ST_X(ST_Centroid(#{geom}))").map(&:to_f)
    end

    def point_on_surface
      select_row("SELECT ST_Y(ST_PointOnSurface(#{geom})), ST_X(ST_PointOnSurface(#{geom}))").map(&:to_f)
    end

    def transform(srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Transform(#{geom}, #{find_srid(srid)}))"))
    end

    def multi_polygon
      Charta.new_geometry select_value("SELECT ST_AsEWKT(ST_Multi(ST_CollectionExtract(ST_CollectionHomogenize(ST_Multi(#{geom})), 3)))")
    end

    def convert_to(type)
      if type == :multi_polygon
        multi_polygon
      else
        self
      end
    end

    def circle(radius)
      ActiveSupport::Deprecation.warn 'Charta.circle is deprecated. Please use Charta.buffer instead.'
      buffer(radius)
    end

    # Produces buffer
    def buffer(radius)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Buffer(#{geom}, #{radius}))"))
    end

    # def merge!(other_geometry)
    #   @ewkt = self.merge(other_geometry).ewkt
    # end

    def merge(other_geometry)
      other = Charta.new_geometry(other_geometry).transform(srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Union(#{geom}, #{other.geom}))"))
    end
    alias + merge

    def intersection(other_geometry)
      other = Charta.new_geometry(other_geometry).transform(srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Multi(ST_CollectionExtract(ST_CollectionHomogenize(ST_Multi(ST_Intersection(#{geom}, #{other.geom}))), 3)))"))
    end

    def difference(other_geometry)
      other = Charta.new_geometry(other_geometry).transform(srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Multi(ST_CollectionExtract(ST_CollectionHomogenize(ST_Multi(ST_Difference(#{geom}, #{other.geom}))), 3)))"))
    end
    alias - difference

    def bounding_box
      unless @bounding_box
        values = select_row('SELECT ' + [:YMin, :XMin, :YMax, :XMax].collect do |v|
                                          "ST_#{v}(#{geom})"
                                        end.join(', ')).map(&:to_f)
        [:y_min, :x_min, :y_max, :x_max].each_with_index do |val, index|
          instance_variable_set("@#{val}", values[index])
        end
        @bounding_box = BoundingBox.new(*values)
      end
      @bounding_box
    end

    delegate :x_min, to: :bounding_box

    delegate :y_min, to: :bounding_box

    delegate :x_max, to: :bounding_box

    delegate :y_max, to: :bounding_box

    def select_value(query)
      Charta.select_value(query)
    end

    def select_values(query)
      Charta.select_values(query)
    end

    def select_row(query)
      Charta.select_row(query)
    end

    def find_srid(name_or_srid)
      Charta.find_srid(name_or_srid)
    end
  end
end
