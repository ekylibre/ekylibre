module Ekylibre
  module Record
    module HasShape #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      class << self
        def clean_for_active_record(value, options = {})
          return nil if value.to_s =~ /\A[[:space:]]*\z/
          return value if value.is_a? RGeo::Feature::Instance

          value = if value.is_a?(Hash) || (value.is_a?(String) && value =~ /\A\{.*\}\z/)
                    begin
                      Charta.from_geojson(value)
                    rescue => e
                      fixed_geojson = correct_geojson(value)
                      value = fixed_geojson.get if fixed_geojson.is_some?
                    end
                  else
                    Charta.new_geometry(value)
                  end

          fixed_value = correct_shape(value, options[:type])
          value = fixed_value.get if fixed_value.is_some?

          if value.type == :geometry_collection
            extracted_shape = extract_geometries(value, options[:type])
            value = extracted_shape.get if extracted_shape.is_some?
          end

          if options[:type] && options[:type] == :multi_polygon
            value = value.convert_to(:multi_polygon)
          elsif options[:type] && options[:type] == :point
            value = value.convert_to(:point)
          end
          value.to_rgeo
        end

        def correct_geojson(value)
          geojson = Charta::GeoJSON.new(value, "4326")
          correct_shape(geojson, options[:type])
        end

        def correct_shape(shape, type)
          corrector = ShapeCorrector.build
          corrector.try_fix(shape, geometry_type: type)
        end

        def extract_geometries(shape, type)
          corrector = ShapeCorrector.build
          corrector.extract_geometries(shape, type)
        end
      end

      module ClassMethods
        SRID = {
          wgs84: 4326,
          rgf93: 2154
        }.freeze

        # BUG: does not handle polygons with holes in them. If you need the centroid, use `geom_union_centroid` that let Postgis do everything
        def geom_union(column_name)
          plucked_ids = pluck(:id).join(',')

          if plucked_ids.blank?
            Charta.empty_geometry
          else
            conn = connection
            Charta.new_geometry(conn.select_value('SELECT ST_MakeValid(ST_AsEWKT(ST_Union(' + conn.quote_column_name(column_name) + '))) FROM ' + conn.quote_table_name(table_name) + ' WHERE id in (' + plucked_ids + ')'))
          end
        end

        # More robust implementation of geom_union(:column_name).centroid that does everything in Postgis and handles weird geometries that RGeo does not.
        def geom_union_centroid(column_name)
          plucked_ids = pluck(:id).join(',')

          if plucked_ids.blank?
            Charta.empty_geometry
          else
            conn = connection
            Charta.new_geometry(conn.select_value('SELECT ST_AsEWKT(ST_Centroid(ST_Union(' + conn.quote_column_name(column_name) + '))) FROM ' + conn.quote_table_name(table_name) + ' WHERE id in (' + plucked_ids + ')')).feature
          end
        end

        def has_geometry(*columns)
          options = columns.extract_options!
          options[:type] ||= :multi_polygon
          columns.each do |column|
            col = column.to_s
            define_method "#{col}=" do |value|
              self[col] = Ekylibre::Record::HasShape.clean_for_active_record(value, options)
            end

            define_method col do
              self[col].blank? ? nil : Charta.new_geometry(self[col])
            end

            unless %i[point multi_point line_string multi_line_string].include?(options[:type])
              define_method "#{col}_area" do |unit = nil|
                return 0.in(unit || :square_meter) if send(col).nil?

                if unit
                  send(col).area.in(:square_meter).in(unit)
                else
                  send(col).area.in(:square_meter)
                end
              end

              define_method "human_#{col}_area" do |mode = :metric|
                area = (send(col) ? send(col + '_area') : 0.in_square_meter)
                if mode == :imperial
                  area.in(:acre).round(3).l
                else # metric
                  area.in_hectare.round(3).l
                end
              end
            end

            define_method "#{col}_centroid" do |_unit = nil|
              send(col).centroid
            end

            scope col + '_overlapping', lambda { |shape|
              where('ST_Overlaps(' + col + ', ST_GeomFromEWKT(?))', ::Charta.new_geometry(shape).to_ewkt)
            }

            scope col + '_covering', lambda { |shape, margin = 0|
              ewkt = ::Charta.new_geometry(shape).to_ewkt
              if margin > 0
                common = 1 - margin
                where('(ST_Overlaps(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) AND ST_Area(ST_Intersection(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))) / ST_Area(ST_GeomFromEWKT(ST_MakeValid(?))) >= ?)', ewkt, ewkt, ewkt, common)
              else
                where('ST_Covers(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ewkt)
              end
            }

            scope col + '_intersecting', lambda { |shape|
              where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ::Charta.new_geometry(shape).to_ewkt)
            }

            scope col + '_surface_intersecting', lambda { |shape|
              where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) AND ST_Area(ST_Intersection(ST_MakeValid(' + col + '), ST_GeomFromEWKT(ST_MakeValid(?)))) > ?', ::Charta.new_geometry(shape).to_ewkt, ::Charta.new_geometry(shape).to_ewkt, 1E-10)
            }

            scope col + '_covered_by', lambda { |shape|
              where('ST_CoveredBy(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ::Charta.new_geometry(shape).to_ewkt)
            }

            scope col + '_within', lambda { |shape|
              where('ST_Within(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ::Charta.new_geometry(shape).to_ewkt)
            }

            scope col + '_matching', lambda { |shape, margin = 0.05|
              ewkt = ::Charta.new_geometry(shape).to_ewkt
              common = 1 - margin
              where('ST_Equals(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) OR (ST_Overlaps(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?))) AND ST_Area(ST_Intersection(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))) / ST_Area(' + col + ') >= ? AND ST_Area(ST_Intersection(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))) / ST_Area(ST_GeomFromEWKT(ST_MakeValid(?))) >= ?)', ewkt, ewkt, ewkt, common, ewkt, ewkt, common)
            }

            scope col + '_near', lambda { |shape, max_distance_in_meter = 5000|
              c = ::Charta.new_geometry(shape).buffer(max_distance_in_meter)
              ewkt = ::Charta.new_geometry(c).to_ewkt
              where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ewkt)
            }

            scope col + '_nearest_of_and_within', lambda { |shape, max_distance_in_meter = 5000|
              c = ::Charta.new_geometry(shape).buffer(max_distance_in_meter)
              ewkt = ::Charta.new_geometry(c).to_ewkt
              where( col + ' IN (?)', select(col)
                                      .where('ST_Intersects(' + col + ', ST_GeomFromEWKT(ST_MakeValid(?)))', ewkt)
                                      .order('ST_Distance(' + col + ', ST_Centroid(\'' + ewkt + '\')) ASC')
                                      .limit(1))
            }

            scope :without_intersected_with_selection, ->(*selected_ids){
              joins(<<~SQL).where('selecteds.id IS NULL')
                LEFT JOIN (#{self.where(id: selected_ids).to_sql}) AS selecteds
                ON (ST_INTERSECTS(#{self.table_name}.#{col}, selecteds.#{col})
                  AND NOT ST_TOUCHES(#{self.table_name}.#{col}, selecteds.#{col}))
                  AND #{self.table_name}.id != selecteds.id
              SQL
            }

            scope :in_bounding_box, ->(bounding_box){
              where("#{self.table_name}.#{col} && ST_MakeEnvelope(#{bounding_box})")
            }

            scope 'without_intersected_with_' + col, ->(shape){
              joins(<<~SQL).where('table_2.intersect_with_shape = FALSE')
                LEFT JOIN (SELECT (ST_INTERSECTS(#{self.table_name}.#{col}, '#{shape}')
                                  AND NOT ST_TOUCHES(#{self.table_name}.#{col}, '#{shape}')) AS intersect_with_shape,
                                  id
                          FROM #{self.table_name}) as table_2
                          ON #{self.table_name}.id = table_2.id
              SQL
            }
          end
        end

        # Returns the corresponding SRID from its name or number
        def srid(srname)
          return srname if srname.is_a?(Integer)
          unless id = SRID[srname]
            raise ArgumentError.new("Unreferenced SRID: #{srname.inspect}")
          end

          id
        end

        def has_shape(*indicators)
          options = (indicators[-1].is_a?(Hash) ? indicators.delete_at(-1) : {})
          code = ''
          indicators = [:shape] if indicators.empty?
          column = :geometry_value

          indicators.each do |indicator|
            # code << "after_create :create_#{indicator}_images\n"

            # code << "before_update :update_#{indicator}_images\n"

            code << "def self.#{indicator}_view_box(options = {})\n"
            code << "  expr = (options[:srid] ? \"ST_Transform(#{column}, \#{self.srid(options[:srid])})\" : '#{column}')\n"
            code << "  ids = ProductReading.of_products(self, :#{indicator}, options[:at]).pluck(:id)\n"
            code << "  return [] unless ids.any?\n"
            code << "  values = self.connection.select_one(\"SELECT min(ST_XMin(\#{expr})) AS x_min, min(ST_YMin(\#{expr})) AS y_min, max(ST_XMax(\#{expr})) AS x_max, max(ST_YMax(\#{expr})) AS y_max FROM \#{ProductReading.indicator_table_name(:#{indicator})} WHERE id IN (\#{ids.join(',')})\").symbolize_keys\n"
            code << "  return [values[:x_min].to_f, -values[:y_max].to_f, (values[:x_max].to_f - values[:x_min].to_f), (values[:y_max].to_f - values[:y_min].to_f)]\n"
            code << "end\n"

            # As SVG
            code << "def self.#{indicator}_svg(options = {})\n"
            # code << "  options[:srid] ||= 2154\n"
            code << "  ids = ProductReading.of_products(self, :#{indicator}, options[:at]).pluck(:product_id)\n"
            code << "  svg = '<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"'\n"
            code << "  return (svg + '/>').html_safe unless ids.any?\n"
            code << "  svg << ' class=\"#{indicator}\" preserveAspectRatio=\"xMidYMid meet\" width=\"100%\" height=\"100%\" viewBox=\"' + #{indicator}_view_box(options).join(' ') + '\"'\n"
            code << "  svg << '>'\n"
            code << "  for product in Product.where(id: ids)\n"
            code << "    svg << '<path d=\"' + product.#{indicator}_to_svg_path(options) + '\"/>'\n"
            code << "  end\n"
            code << "  svg << '</svg>'\n"
            code << "  return svg.html_safe\n"
            code << "end\n"

            # Return SVG as String
            code << "def #{indicator}_svg(options = {})\n"
            code << "  options[:srid] ||= 2154\n"
            code << "  return nil unless reading = self.reading(:#{indicator}, at: options[:at])\n"
            code << "  geom = Charta.new_geometry(self.#{indicator})\n"
            code << "  geom = geom.transform(options[:srid]) if options[:srid]\n"
            code << "  return geom.to_svg(options)\n"
            # code << "  options[:srid] ||= 2154\n"
            # code << "  return ('<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\""
            # for attr, value in {:class => indicator, :preserve_aspect_ratio => 'xMidYMid meet', :width => 180, :height => 180, :view_box => "self.#{indicator}_view_box(options).join(' ')".c}
            #   code << " #{attr.to_s.camelcase(:lower)}=\"' + (options[:#{attr}] || #{value.inspect}).to_s + '\""
            # end
            # code << "><path d=\"' + self.#{indicator}_to_svg(options).to_s + '\"/></svg>').html_safe\n"
            code << "end\n"

            # Return ViewBox
            code << "def #{indicator}_view_box(options = {})\n"
            code << "  return nil unless reading = self.reading(:#{indicator}, at: options[:at])\n"
            code << "  return [self.#{indicator}_x_min(options), -self.#{indicator}_y_max(options), self.#{indicator}_width(options), self.#{indicator}_height(options)]\n"
            code << "end\n"

            %i[x_min x_max y_min y_max to_svg to_svg_path to_gml to_kml to_geojson to_text to_binary to_ewkt centroid point_on_surface].each do |attr|
              code << "def #{indicator}_#{attr.to_s.downcase}(options = {})\n"
              code << "  return nil unless reading = self.reading(:#{indicator}, at: options[:at])\n"
              code << "  geometry = Charta.new_geometry(reading.#{column})\n"
              code << "  geometry = geometry.transform(options[:srid]) if options[:srid]\n"
              code << "  return geometry.#{attr}\n"
              code << "end\n"
            end

            code << "def #{indicator}_area(options = {})\n"
            code << "  return nil unless reading = self.reading(:#{indicator}, at: options[:at])\n"
            code << "  geometry = Charta.new_geometry(reading.#{column})\n"
            code << "  geometry = geometry.transform(options[:srid]) if options[:srid]\n"
            code << "  return geometry.area.in_square_meter\n"
            code << "end\n"

            # # add a method to convert polygon to point
            # # TODO : change geometry_value to a variable :column
            # for attr in [:centroid, :point_on_surface]
            #   code << "def #{indicator}_#{attr.to_s.downcase}(options = {})\n"
            #   code << "  return nil unless reading = self.reading(:#{indicator}, at: options[:at])\n"
            #   code << "  self.class.connection.select_value(\"SELECT ST_#{attr.to_s.camelcase}(geometry_value) FROM \#{ProductReading.indicator_table_name(:#{indicator})} WHERE id = \#{reading.id}\")\n"
            #   code << "end\n"
            # end

            code << "def #{indicator}_width(options = {})\n"
            code << "  return (self.#{indicator}_x_max(options) - self.#{indicator}_x_min(options))\n"
            code << "end\n"

            code << "def #{indicator}_height(options = {})\n"
            code << "  return (self.#{indicator}_y_max(options) - self.#{indicator}_y_min(options))\n"
            code << "end\n"
          end

          # code.split(/\n/).each_with_index{|l, i| puts (i+1).to_s.rjust(4) + ": " + l}

          class_eval code
        end
      end
    end
  end
end
