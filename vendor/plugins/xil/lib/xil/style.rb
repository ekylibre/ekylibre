require 'measure'


module Ekylibre
  module Xil

    class Color
      attr_reader :red, :blue, :green

      def initialize(value)
        @red, @green , @blue = 255, 0, 255
        if value.is_a? self.class
          @red, @green, @blue = value.red, value.green, value.blue
        elsif value.is_a? String
          value = "#"+value[1..1]*2+value[2..2]*2+value[3..3]*2 if value=~/^\#[a-f0-9]{3}$/i
          value = if value=~/^\#[a-f0-9]{6}$/i
                    [value[1..2].to_i(16), value[3..4].to_i(16), value[5..6].to_i(16)]
                  elsif value=~/rgb\(\d+\,\d+\,\d+\)/i
                    array = value.split /(\(|\,|\))/
                    [array[2].strip, array[4].strip, array[6].strip].collect{|x| x[/\d*\.\d*/].to_f }
                  elsif value=~/rgb\(\d+\%\,\d+\%\,\d+\%\)/i
                    array = value.split /(\(|\,|\))/
                    [array[2].strip, array[4].strip, array[6].strip].collect{|x| x[/\d*\.\d*/].to_f*2.55 }
                  end
          @red, @green, @blue = value[0], value[1], value[2]
        end
      end
      
      def to_a
        [@red, @green, @blue]
      end
    end


    class Line
      def initialize(value)
        if value.is_a? self.class
          @width, @style, @color = self.width, self.style, self.color
        else
          value = value.strip.squeeze(" ").split[0..2] if value.is_a? String
        raise Exception.new('Unvalid line value: '+value.inspect) unless value.is_a? Array
          @width = ::Measure.new(value[0], :nature=>'m')
          @style = :solid
          @color = Color.new(value[2])
        end
      end

      def to_a
        [@width, @style, @color]
      end
      
    end




    class Style

      attr_reader :properties

      PROPERTIES = {
        'padding'=>{:nature=>:length4},
        'margin'=>{:nature=>:length4},
        'border'=>{:nature=>:line},
        'top'=>{:nature=>:length},
        'left'=>{:nature=>:length},
        'width'=>{:nature=>:length},
        'height'=>{:nature=>:length},
        'background'=>{:nature=>:color},
        'color'=>{:nature=>:color},
        'font-size'=>{:nature=>:length},
        'font-family'=>{:nature=>['helvetica', 'times', 'courier', 'symbol', 'zapfdingbats']},
        'font-weight'=>{:nature=>['normal', 'bold']},
        'font-style'=>{:nature=>['normal', 'italic']},
        'text-align'=>{:nature=>['left', 'center', 'right', 'justify']},
        'text-decoration'=>{:nature=>['none', 'underline']},
        'vertical-align'=>{:nature=>['top', 'middle', 'bottom']},
        'rotate'=>{:nature=>:angle},
        'size'=>{:nature=>:format}
      }

      FORMATS = {
        'a0'=>[Measure.new(840, :mm), Measure.new(1189, :mm)],
        'a1'=>[::Measure.new(594, :mm), ::Measure.new(841, :mm)],
        'a2'=>[::Measure.new(420, :mm), ::Measure.new(594, :mm)],
        'a3'=>[::Measure.new(297, :mm), ::Measure.new(420, :mm)],
        'a4'=>[::Measure.new(210, :mm), ::Measure.new(297, :mm)],
        'a5'=>[::Measure.new(148, :mm), ::Measure.new(210, :mm)],
        'a6'=>[::Measure.new(105, :mm), ::Measure.new(148, :mm)],
        'letter'=>[::Measure.new(11, :in), ::Measure.new(8.5, :in)],
        'legal'=> [::Measure.new(14, :in), ::Measure.new(8.5, :in)],
        'ledger'=>[::Measure.new(17, :in), ::Measure.new(11, :in)],
      }

      DEFAULT_FORMAT = 'a4'
      
      def initialize(style=nil)
        @properties = {}
        self.merge!(style) unless style.nil?
      end

      def parse(text)
        @properties = {}
        array = text.to_s.split ';'
        for item in array
          couple = item.split(':')
          self.set(couple[0], couple[1]) if couple.size == 2
        end
      end

      def set(property, value)
        property = property.strip.downcase
        value = Style.property_value(property, value)
        @properties[property] = value unless value.nil?
      end

      def get(property, default=nil)
        raise Exception.new("Unvalid property "+property) unless PROPERTIES.include? property
        prop = @properties[property]
        prop ||= Style.property_value(property, default) unless default.nil?
        prop
      end

      def to_ssss
        style = ''
        for prop, value in @properties
          style += prop+':'
          if value.is_a? Array
            style += value.join(' ')
          else
            style += value.to_s
          end
          style += ';'
        end
        style
      end

      def dup
        Style.new(@properties)
      end

      def merge(style)
        merged = self.dup
        merged.merge!(style.properties)
        merged
      end

      def merge!(style)
        return self if style.nil?
        style = style.properties if style.is_a? self.class
        if style.is_a? String
          self.parse(style)
        elsif style.is_a? Hash
          @properties.merge(style)
#          for prop, value in style
#            puts [prop, value].inspect
#            self.set(prop, value)
#          end
        end
        self
      end

      private

      def self.property_value(property, value)
        raise Exception.new("Unvalid property "+property) unless PROPERTIES.include? property
        value = value.strip if value.is_a? String
        definition = PROPERTIES[property]
        if definition.is_a? Hash
          if definition[:nature].is_a? Symbol
            value = Style.send("string_to_#{definition[:nature].to_s}", value)
          elsif definition[:nature].is_a? Array
            value = nil unless definition[:nature].include? value
          else
            raise Exception.new('Bad property definition: '+property)
          end
        else
          raise Exception.new('Bad property definition: '+property)
        end
      end

      def self.string_to_length(value)
        m = ::Measure.new(value)
        m = ::Measure.new(0, :mm) if ::Measure.dimension(m.unit) != :length
        m
      end

      def self.string_to_angle(value)
        m = ::Measure.new(value)
        m = ::Measure.new(0, :rad) if ::Measure.dimension(m.unit) != :angle
        m
      end

      def self.string_to_length4(value)
        value = value.strip.squeeze(" ").split[0..3].collect{|l| Style.string_to_length(l)}
        value[1] ||= value[0]
        value[2] ||= value[0]
        value[3] ||= value[1]
        value
      end 

      def self.string_to_color(value)
        return value.concat([0,0,0]).flatten[0..2] if value.is_a? Array
        value = "#"+value[1..1]*2+value[2..2]*2+value[3..3]*2 if value=~/^\#[a-f0-9]{3}$/i
        if value=~/^\#[a-f0-9]{6}$/i
          [value[1..2].to_i(16), value[3..4].to_i(16), value[5..6].to_i(16)]
        elsif value=~/rgb\(\d+\,\d+\,\d+\)/i
          array = value.split /(\(|\,|\))/
          [array[2].strip, array[4].strip, array[6].strip].collect{|x| x[/\d*\.\d*/].to_f }
        elsif value=~/rgb\(\d+\%\,\d+\%\,\d+\%\)/i
          array = value.split /(\(|\,|\))/
          [array[2].strip, array[4].strip, array[6].strip].collect{|x| x[/\d*\.\d*/].to_f*2.55 }
        else
          #raise Exception.new value.to_s
          [255, 0, 255]
        end
      end

      def self.string_to_line(value)
        value = value.strip.squeeze(" ").split[0..2] if value.is_a? String
        raise Exception.new('Unvalid line value: '+value.inspect) unless value.is_a? Array
        value[0] = Style.string_to_length(value[0])
        value[1] = :solid
        value[2] = Style.string_to_color(value[2])
        value
      end

      def self.string_to_format(value)
        value = value.strip.squeeze(" ").split[0..1]        
        value = [DEFAULT_FORMAT, value[0]] if value.size==1
        if ['landscape', 'portrait'].include? value[1]
          orientation = value[1]
          value = FORMATS[value[0].downcase]
          value.reverse if orientation == 'landscape'
        else
          value = value.collect{|l| Style.string_to_length(l)}
        end
        value = Style.string_to_format('portrait') if value[0].nil? or value[1].nil?
        value
      end


    end


  end
end
