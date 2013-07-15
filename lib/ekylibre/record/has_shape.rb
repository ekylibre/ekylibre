module Ekylibre::Record
  module HasShape #:nodoc:

    def self.included(base)
      base.extend(ClassMethods)
    end

    class Code < String
      def inspect
        self.to_s
      end
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

      def has_shape(*args)
        options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
        code = ""
        args = [:shape] if args.empty?
        for column in args
          code << "after_create :create_#{column}_images\n"

          code << "before_update :update_#{column}_images\n"

          code << "def #{column}_dir\n"
          code << "  Ekylibre.private_directory.join('shapes', '#{self.name.underscore.pluralize}', '#{column}', self.id.to_s)\n"
          code << "end\n"

          # Return SVG as String
          code << "def #{column}_svg(options = {})\n"
          code << "  return '<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\""
          for attr, value in {:class => column, :preserve_aspect_ratio => 'xMidYMid meet', :width => 180, :height => 180, :view_box => Code.new("self.#{column}_view_box.join(' ')")}
            code << " #{attr.to_s.camelcase(:lower)}=\"' + (options[:#{attr}] || #{value.inspect}).to_s + '\""
          end
          code << "><path d=\"' + self.#{column}_as_svg.to_s + '\"/></svg>'\n"
          code << "end\n"

          code << "def #{column}_view_box(options = {})\n"
          code << "  return [self.#{column}_x_min(options), -1 * self.#{column}_y_max(options).to_d, self.#{column}_width(options), self.#{column}_height(options)]\n"
          code << "end\n"

          code << "def #{column}_path(format = :original)\n"
          code << "  return self.#{column}_dir.join(format.to_s + '.' + (format == :original ? 'svg' : 'png'))\n"
          code << "end\n"

          for attr in [:x_min, :x_max, :y_min, :y_max, :area, :as_svg, :as_gml, :as_kml, :as_geojson]
            code << "def #{column}_#{attr.to_s.downcase}(options = {})\n"
            code << "  column = (options[:srid] ? \"ST_Transform(#{column}, \#{self.class.srid(options[:srid])})\" : '#{column}')\n"
            code << "  self.class.connection.select_value(\"SELECT ST_#{attr.to_s.camelcase}(\#{column}) FROM \#{self.class.table_name} WHERE id = \#{self.id}\")#{'.to_d rescue 0' unless attr.to_s =~ /^as\_/}\n"
            code << "end\n"
          end

          code << "def #{column}_width(options = {})\n"
          code << "  return (#{column}_x_max(options) - #{column}_x_min(options))\n"
          code << "end\n"

          code << "def #{column}_height(options = {})\n"
          code << "  return (#{column}_y_max(options) - #{column}_y_min(options))\n"
          code << "end\n"

          code << "def create_#{column}_images\n"
          code << "  FileUtils.mkdir_p(self.#{column}_dir)\n"
          code << "  source = self.#{column}_dir.join('original.svg')\n"
          # Create SVG
          code << "  File.open(source, 'wb') do |f|\n"
          code << "    f.write(self.#{column}_svg)\n"
          code << "  end\n"

          for format, convert_options in options[:formats]
            # Convert to PNG
            code <<  "  export = self.#{column}_dir.join('#{format}.png')\n"
            code <<  "  system('inkscape --export-png=' + Shellwords.escape(export.to_s)"
            for name, value in convert_options
              code <<  " + ' --export-#{name.to_s.dasherize}=' + Shellwords.escape(#{value.to_s.inspect})"
            end
            code <<  "+ ' ' + source.to_s)\n"
          end if options[:formats]
          code << "end\n"

          code << "def update_#{column}_images\n"
          code << "  old = self.class.find(self.id) \n"
          code << "  if old.#{column} != self.#{column}\n"
          code << "    self.create_#{column}_images\n"
          code << "  end\n"
          code << "end\n"

        end

        code.split(/\n/).each_with_index{|l, i| puts i.to_s.rjust(4) + ": " + l}
        class_eval code
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::HasShape)
