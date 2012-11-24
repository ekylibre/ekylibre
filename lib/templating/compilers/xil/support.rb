module Templating::Compilers
  module Xil
    module Schema

      class Definition
        def initialize(*args, &block)
          @elements = {}
          self.instance_eval(&block) if block_given?
        end

        def element(name, attributes={}, content=nil, &block)
          required_attributes = {}
          for attr_name, type in attributes
            required_attributes[attr_name.to_s[0..-2]] = type if attr_name.to_s.match(/\!$/)
          end
          attributes.delete_if{|k,v| k.to_s.match(/\!$/)}
          self[name] = Element.new(name, content, required_attributes, attributes, &block)
        end

        def [](name)
          @elements[name.to_s]
        end

        def []=(name, value)
          raise ArgumentError.new("Element expected") unless value.is_a?(Element)
          @elements[name.to_s] = value
        end
      end

      class Element
        attr_reader :children, :content

        def initialize(name, type=nil, required_attributes = {}, attributes = {}, &block)
          @name = name.to_s
          unless type.nil?
            raise ArgumentError.new("Unknown type #{type.inspect}") unless Templating::Compilers::Xil::Schema::Attribute::TYPES.include?(type)
          end
          @content = type
          @children = []
          @attributes = {}
          for name, type in attributes
            @attributes[name.to_s] = Attribute.new(name, type, false)
          end
          for name, type in required_attributes
            @attributes[name.to_s] = Attribute.new(name, type, true)
          end
          self.instance_eval(&block) if block_given?
        end

        # Returns attribute def
        def [](name)
          @attributes[name.to_s]
        end

        def attributes
          @attributes.collect{|name, attribute| attribute}
        end

        def required_attributes
          attributes.select{|attribute| attribute.required?}
        end

        def has_content?
          !@content.nil?
        end

        def has(occurrences, *children)
          options = (children[-1].is_a?(Hash) ? children.delete_at(-1) : {})
          for child in children
            child = child.to_s.singularize if child.is_a? Symbol
            child = child.to_s
            @children << child unless @children.include?(child)
          end
        end

        def has_many(*children)
          for child in children
            child = child.to_s.singularize unless child.is_a? String
            @children << child unless @children.include?(child)
          end
        end

        def has_one(*children)
          for child in children
            child = child.to_s
            @children << child unless @children.include?(child)
          end
        end

        def read(string)
          Templating::Compilers::Xil::Schema::Attribute.read(string, @content)
        end

      end


      class Attribute
        attr_reader :name, :type
        TYPES = [:boolean, :stroke, :color, :integer, :length4, :length, :page_format, :path, :property, :string, :symbol, :variable]

        def initialize(name, type=:string, required=false)
          @name = name.to_s
          raise ArgumentError.new("Unknown type #{type.inspect}") unless TYPES.include?(type)
          @type = type
          @required = required
        end

        def required?
          @required
        end

        def read(string)
          self.class.read(string, @type)
        end

        # Read a string and interprets it using the type
        def self.read(string, type)
          string = string.to_s # Ensure that it is a String
          if type == :string or type == :property or type == :variable
            string
          elsif type == :boolean
            (string.downcase == 'true' ? true : false)
          elsif type == :stroke
            array = string.strip.split(/\s+/)
            raise Exception.new("Attribute border malformed: #{string.inspect}. Ex.: '1mm solid #123456'") if array.size != 3
            {:width=> measure_to_float(array[0]), :style=>array[1].to_sym, :color=>array[2].to_s}
          elsif type == :integer
            string.to_i
          elsif type == :length
            measure_to_float(string)
          elsif type == :length4
            array = string.split(/\s+/)
            array[0] = measure_to_float(array[0])
            array[1] = measure_to_float(array[1]||array[0].to_s)
            array[2] = measure_to_float(array[2]||array[0].to_s)
            array[3] = measure_to_float(array[3]||array[1].to_s)
            array
          elsif type == :page_format
            if string.match(/(x|\s+)/)
              string.split(/(x|\s+)/)[0..1].collect{|x| measure_to_float(x.strip)}
            elsif Prawn::Document::PageGeometry::SIZES[string.upcase]
              Prawn::Document::PageGeometry::SIZES[string.upcase]
            elsif string.blank?
              nil
            else
              raise Exception.new("Unreadable '#{type}': #{string.inspect}")
            end
          elsif type == :path
            string.split(/\s*\;\s*/).collect{|point| point.split(/\s*\,\s*/).collect{|m| measure_to_float(m)}}
          elsif type == :symbol
            (string.blank? ? nil : string.to_sym)
          else
            raise ArgumentError.new("Unreadable type: #{type.inspect}")
          end
        end

        private

        def self.measure_to_float(string, width = (210.mm - 2 * 10.mm))
          string = string.to_s
          m = if string.match(/^\-?\d+(\.\d*)?mm$/)
                string[0..-3].to_d.mm
              elsif string.match(/^\-?\d+(\.\d*)?cm$/)
                string[0..-3].to_d.cm
              elsif string.match(/^\-?\d+(\.\d*)?pc$/)
                string[0..-3].to_d * 12
              elsif string.match(/^\-?\d+(\.\d*)?in$/)
                string[0..-3].to_d.in
              elsif string.match(/^\-?\d+(\.\d*)?pt$/)
                string[0..-3].to_d
              elsif string.match(/^\-?\d+(\.\d*)?$/)
                string.to_d
              elsif string.blank?
                0
              elsif string.match(/^\-?\d+(\.\d*)?\%$/)
                # puts "DEPRECATED: Use of percentage for lengths is deprecated because since Templating the reference width is fixed (#{width.to_s}pt)"
                string[0..-2].to_d*width.to_d/100.0
              else
                raise ArgumentError.new("Unvalid string to convert to float: #{string.inspect}")
              end
          return m
        end

      end


    end

  end
end
