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

        def initialize(name, type=:string, required=false)
          @name = name.to_s
          @type = type
          @required = required
        end

        def required?
          @required
        end
      end


    end
    
  end
end
