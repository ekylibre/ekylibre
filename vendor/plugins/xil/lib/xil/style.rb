module Ekylibre
  module Xil

    class Measure

      UNITS = {
        'mm'=>{:nature=>'m', :factor=>0.001},
        'cm'=>{:nature=>'m', :factor=>0.01},
        'dm'=>{:nature=>'m', :factor=>0.1},
        'm'=> {:nature=>'m', :factor=>1},
        'km'=>{:nature=>'m', :factor=>1000},
        'pt'=>{:nature=>'m', :factor=>0.0254/72},
        'pc'=>{:nature=>'m', :factor=>0.0254/6},
        'in'=>{:nature=>'m', :factor=>0.0254}, # 2.54cm
        'ft'=>{:nature=>'m', :factor=>12*0.0254}, # 12 in
        'yd'=>{:nature=>'m', :factor=>3*12*0.0254},  # 3 ft
        'mi'=>{:nature=>'m', :factor=>1760*3*12*0.0254} # 1760 yd
      }

      
      def initialize(value, unit=nil)
        if value.is_a? String
          numeric = value[/\d*\.?\d*/]
          raise ArgumentError.new("Unvalid value: #{value.inspect}") if numeric.nil?
          unit = value[/[a-z]+/]
        else
          numeric = value
        end
        begin
          @value = numeric.to_f
        rescue
          raise ArgumentError.new("Value can't be converted to float: #{value.inspect}")
        end
        raise ArgumentError.new("Unknown unit: #{value.inspect}") unless UNITS.keys.include? unit
        @unit = unit
      end

      def to_m(unit)
        Measure.new(self.to_f(unit), unit)
      end

      def inspect
        @value.to_f.to_s+@unit
      end

      def +(measure)
        @value += measure.to_f(@unit)
      end

      def -(measure)
        @value -= measure.to_f(@unit)
      end

      def to_f(unit=nil)
        if unit.nil?
          @value
        else
          raise Exception.new("Unknown unit: #{unit.inspect}") unless UNITS.keys.include? unit
          raise Exception.new("Measure can't be converted from one system (#{UNITS[@unit][:nature].inspect}) to an other (#{UNITS[unit][:nature].inspect})") if UNITS[@unit][:nature]!=UNITS[unit][:nature]
          @value*UNITS[@unit][:factor]/UNITS[unit][:factor]
        end
      end
      
      def to_s
        @value.to_f.to_s+@unit
      end
      
    end


    class Style

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
        'font-weight'=>{:nature=>['normal', 'bold']},
        'font-style'=>{:nature=>['normal', 'italic']},
        'text-align'=>{:nature=>['left', 'center', 'right', 'justify']},
        'text-decoration'=>{:nature=>['none', 'underline']},
        'vertical-align'=>{:nature=>['top', 'middle', 'bottom']},
        'size'=>{:nature=>:format}
      }

      FORMATS = {
        'a0'=>[Measure.new('840mm'), Measure.new('1189mm')],
        'a1'=>[Measure.new('594mm'), Measure.new('841mm')],
        'a2'=>[Measure.new('420mm'), Measure.new('594mm')],
        'a3'=>[Measure.new('297mm'), Measure.new('420mm')],
        'a4'=>[Measure.new('210mm'), Measure.new('297mm')],
        'a5'=>[Measure.new('148mm'), Measure.new('210mm')],
        'a6'=>[Measure.new('105mm'), Measure.new('148mm')],
        'letter'=>[Measure.new('11in'), Measure.new('8.5in')],
        'legal'=> [Measure.new('14in'), Measure.new('8.5in')],
        'ledger'=>[Measure.new('17in'), Measure.new('11in')],
      }

      DEFAULT_FORMAT = 'a4'
      
      def initialize(text)
        self.parse(text)
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
        value = value.strip if value.is_a? String
        definition = PROPERTIES[property]
        if definition.is_a? Hash
          if definition[:nature].is_a? Symbol
            value = Style.send("string_to_#{definition[:nature].to_s}", value.to_s)
            @properties[property] = value unless value.nil?
          elsif definition[:nature].is_a? Array
            @properties[property] = value if definition[:nature].include? value
          else
            raise Exception.new('Bad property definition: '+property)
          end
        end
      end

      def get(property)
        @properties[property]
      end

      private

      def self.string_to_length(value)
        Measure.new(value)
      end

      def self.string_to_length4(value)
        value = value.strip.squeeze(" ").split[0..3].collect{|l| Style.string_to_length(l)}
        value[1] ||= value[0]
        value[2] ||= value[0]
        value[3] ||= value[1]
        value
      end 

      def self.string_to_color(value)
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
        value = value.strip.squeeze(" ").split[0..2]
        value[0] = Style.string_to_length(value[0])
        value[1] = 'solid'
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
