module Templating::Compilers
  module Xil
    module Schema

      class Definition
        def initialize(*args, &block)
          @elements = {}
          self.instance_eval(&block) if block_given?
        end
        
        def element(name, content=nil, required_attributes = {}, attributes = {}, &block)
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

        def initialize(name, content=nil, required_attributes = {}, attributes = {}, &block)
          @name = name.to_s
          @content = content
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

        def has_many(*children)
          for child in children
            child = child.to_s.singularize
            @children << child unless @children.include?(child)
          end
        end
        
      end

      
      class Attribute
        attr_reader :name, :type
        TYPES = [:boolean, :border, :color, :length4, :length, :page_format, :path, :property, :symbol, :variable]

        def initialize(name, type=:string, required=false)
          @name = name.to_s
          @type = type
          raise ArgumentError.new("Unknown type #{@type.inspect}") unless TYPES.include?(@type)
          @required = required
        end

        def required?
          @required
        end

        # Read a string and interprets it using the type
        def read(string)
          string = string.to_s # Ensure that it is a String
          if @type == :string
            string
          elsif @type == :boolean
            (string.downcase == 'true' ? true : false)
          elsif @type == :integer
            string.to_i
          elsif @type == :length
            measure_to_float(string)
          elsif @type == :length4
            array = string.split(/\s+/)
            array[0] = measure_to_float(array[0])
            array[1] = measure_to_float(array[1]||array[0].to_s)
            array[2] = measure_to_float(array[2]||array[0].to_s)
            array[3] = measure_to_float(array[3]||array[1].to_s)
            array
          elsif @type == :page_format
            if string.match(/(x|\s+)/)
              string.split(/(x|\s+)/)[0..1].collect{|x| measure_to_float(x.strip)}
            elsif Prawn::Document::PageGeometry::SIZES[string.upcase]
              Prawn::Document::PageGeometry::SIZES[string.upcase]
            else
              raise Exception.new("Unreadable #{@type}: #{string.inspect}")
            end
          elsif @type == :symbol
            (string.blank? ? nil : string.to_sym)
          else
            raise ArgumentError.new("Unknown type #{@type.inspect}") unless TYPES.include?(@type)
          end
        end
        
        private 

        def measure_to_float(string)
          string = string.to_s
          m = if string.match(/\-?\d+(\.\d+)?mm/)
                string[0..-3].to_d.mm
              elsif string.match(/\-?\d+(\.\d+)?/)
                string.to_d
              else
                0
              end
          return m.round(2)
        end

      end


    end
    
  end
end
