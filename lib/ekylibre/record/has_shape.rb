module Ekylibre::Record
  module HasShape #:nodoc:

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      SRID = {
        :wgs84 => 4326,
        :rgf93 => 2154
      }

      # Returns the corresponding SRID from its name or number
      def srid(srname)
        return srname if srname.is_a?(Integer)
        unless id = SRID[srname]
          raise ArgumentError.new("Unreferenced SRID: #{srname.inspect}")
        end
        return id
      end

      def has_shape(*indicators)
        options = (indicators[-1].is_a?(Hash) ? indicators.delete_at(-1) : {})
        code = ""
        indicators = [:shape] if indicators.empty?
        column = :geometry_value

        for indicator in indicators
          # code << "after_create :create_#{indicator}_images\n"

          # code << "before_update :update_#{indicator}_images\n"

          # code << "def #{indicator}_dir\n"
          # code << "  Ekylibre.private_directory.join('shapes', '#{self.name.underscore.pluralize}', '#{indicator}', self.id.to_s)\n"
          # code << "end\n"

          code << "def self.#{indicator}_view_box(options = {})\n"
          code << "  expr = (options[:srid] ? \"ST_Transform(#{column}, \#{self.class.srid(options[:srid])})\" : '#{column}')\n"
          code << "  ids = ProductIndicatorDatum.of_products(self, :#{indicator}, options[:at]).pluck(:id)\n"
          code << "  return [] unless ids.any?\n"
          code << "  values = self.connection.select_one(\"SELECT min(ST_XMin(\#{expr})) AS x_min, min(ST_YMin(\#{expr})) AS y_min, max(ST_XMax(\#{expr})) AS x_max, max(ST_YMax(\#{expr})) AS y_max FROM \#{ProductIndicatorDatum.indicator_table_name(:#{indicator})} WHERE id IN (\#{ids.join(',')})\").symbolize_keys\n"
          code << "  return [values[:x_min].to_d, -values[:y_max].to_d, (values[:x_max].to_d - values[:x_min].to_d), (values[:y_max].to_d - values[:y_min].to_d)]\n"
          code << "end\n"

          # As SVG
          code << "def self.#{indicator}_svg(options = {})\n"
          code << "  ids = ProductIndicatorDatum.of_products(self, :shape, options[:at]).pluck(:product_id)\n"
          code << "  svg = '<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"'\n"
          code << "  return (svg + '/>').html_safe unless ids.any?\n"
          code << "  svg << ' class=\"#{indicator}\" preserveAspectRatio=\"xMidYMid meet\" width=\"100%\" height=\"100%\" viewBox=\"' + shape_view_box.join(' ') + '\"'\n"
          code << "  svg << '>'\n"
          code << "  for product in Product.where(id: ids)\n"
          code << "    svg << '<path d=\"' + product.shape_as_svg + '\"/>'\n"
          code << "  end\n"
          code << "  svg << '</svg>'\n"
          code << "  return svg.html_safe\n"
          code << "end\n"

          # Return SVG as String
          code << "def #{indicator}_svg(options = {})\n"
          code << "  return nil unless datum = self.indicator_datum(:#{indicator}, at: options[:at])\n"
          code << "  return ('<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\""
          for attr, value in {:class => indicator, :preserve_aspect_ratio => 'xMidYMid meet', :width => 180, :height => 180, :view_box => "self.#{indicator}_view_box.join(' ')".c}
            code << " #{attr.to_s.camelcase(:lower)}=\"' + (options[:#{attr}] || #{value.inspect}).to_s + '\""
          end
          code << "><path d=\"' + self.#{indicator}_as_svg.to_s + '\"/></svg>').html_safe\n"
          code << "end\n"

          # Return ViewBox
          code << "def #{indicator}_view_box(options = {})\n"
          code << "  return nil unless datum = self.indicator_datum(:#{indicator}, at: options[:at])\n"
          code << "  return [self.#{indicator}_x_min(options), -self.#{indicator}_y_max(options), self.#{indicator}_width(options), self.#{indicator}_height(options)]\n"
          code << "end\n"

          # code << "def #{indicator}_path(format = :original)\n"
          # code << "  return self.#{indicator}_dir.join(format.to_s + '.' + (format == :original ? 'svg' : 'png'))\n"
          # code << "end\n"

          for attr in [:x_min, :x_max, :y_min, :y_max, :area, :as_svg, :as_gml, :as_kml, :as_geojson, :as_text, :as_binary, :as_ewkt]
            code << "def #{indicator}_#{attr.to_s.downcase}(options = {})\n"
            code << "  return nil unless datum = self.indicator_datum(:#{indicator}, at: options[:at])\n"
            code << "  expr = (options[:srid] ? \"ST_Transform(#{column}, \#{self.class.srid(options[:srid])})\" : '#{column}')\n"
            code << "  return self.class.connection.select_value(\"SELECT ST_#{attr.to_s.camelcase}(\#{expr}) FROM \#{ProductIndicatorDatum.indicator_table_name(:#{indicator})} WHERE id = \#{datum.id}\")"
            if attr.to_s =~ /\Aas\_/
              code << ".to_s"
            elsif attr.to_s =~ /area\z/
              code << ".to_d.in_square_meter"
            else
              code << '.to_d rescue 0'
            end
            code << "\n"
            code << "end\n"
          end

          # add a method to convert polygon to point
          # TODO : change geometry_value to a variable :column
          for attr in [:centroid, :point_on_surface]
            code << "def #{indicator}_#{attr.to_s.downcase}(options = {})\n"
            code << "  return nil unless datum = self.indicator_datum(:#{indicator}, at: options[:at])\n"
            code << "  self.class.connection.select_value(\"SELECT ST_#{attr.to_s.camelcase}(geometry_value) FROM \#{ProductIndicatorDatum.indicator_table_name(:#{indicator})} WHERE id = \#{datum.id}\")\n"
            code << "end\n"
          end


          code << "def #{indicator}_width(options = {})\n"
          code << "  return (self.#{indicator}_x_max(options) - self.#{indicator}_x_min(options))\n"
          code << "end\n"

          code << "def #{indicator}_height(options = {})\n"
          code << "  return (self.#{indicator}_y_max(options) - self.#{indicator}_y_min(options))\n"
          code << "end\n"

          # code << "def create_#{indicator}_images\n"
          # code << "  FileUtils.mkdir_p(self.#{indicator}_dir)\n"
          # code << "  source = self.#{indicator}_dir.join('original.svg')\n"
          # # Create SVG
          # code << "  File.open(source, 'wb') do |f|\n"
          # code << "    f.write(self.#{indicator}_svg)\n"
          # code << "  end\n"

          # for format, convert_options in options[:formats]
          #   # Convert to PNG
          #   code <<  "  export = self.#{indicator}_dir.join('#{format}.png')\n"
          #   code <<  "  system('inkscape --export-png=' + Shellwords.escape(export.to_s)"
          #   for name, value in convert_options
          #     code <<  " + ' --export-#{name.to_s.dasherize}=' + Shellwords.escape(#{value.to_s.inspect})"
          #   end
          #   code <<  "+ ' ' + source.to_s)\n"
          # end if options[:formats]
          # code << "end\n"

          # code << "def update_#{indicator}_images\n"
          # code << "  old = self.class.find(self.id) \n"
          # code << "  if old.#{indicator} != self.#{indicator}\n"
          # code << "    self.create_#{indicator}_images\n"
          # code << "  end\n"
          # code << "end\n"

        end

        # code.split(/\n/).each_with_index{|l, i| puts (i+1).to_s.rjust(4) + ": " + l}

        class_eval code
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::HasShape)
