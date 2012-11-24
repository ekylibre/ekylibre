 class Measure
   attr_reader :value, :unit

   @@dimensions = {
     :length=>{:ref=>:m},
     :angle=>{:ref=>:rad},
   }

   @@units = {
     :mm=>{:dimension=>:length, :factor=>0.001},
     :cm=>{:dimension=>:length, :factor=>0.01},
     :dm=>{:dimension=>:length, :factor=>0.1},
     :m=> {:dimension=>:length, :factor=>1},
     :km=>{:dimension=>:length, :factor=>1000},
     :pt=>{:dimension=>:length, :factor=>0.0254/72},
     :pc=>{:dimension=>:length, :factor=>0.0254/6},
     :in=>{:dimension=>:length, :factor=>0.0254}, # 2.54cm
     :ft=>{:dimension=>:length, :factor=>12*0.0254}, # 12 in
     :yd=>{:dimension=>:length, :factor=>3*12*0.0254},  # 3 ft
     :mi=>{:dimension=>:length, :factor=>1760*3*12*0.0254}, # 1760 yd
     :gon=>{:dimension=>:angle, :factor=>Math::PI/200},
     :deg=>{:dimension=>:angle, :factor=>Math::PI/180},
     :rad=>{:dimension=>:angle, :factor=>1},
   }

   class << self

     def units(dimension)
       @@units.select{|k, v| v[:dimension]==dimension}.collect{|k, v| k}
     end

     def dimension(unit)
       @@units[unit][:dimension]
     end
   end


   def initialize(value, unit)
     raise ArgumentError.new("Value can't be converted to float: #{value.inspect}") unless value.is_a? Numeric
     raise ArgumentError.new("Unknown unit: #{unit.inspect}") unless @@units.keys.include? unit
     @value = value.to_f
     @unit = unit
     return nil
   end

   def to_m(unit)
     Measure.new(self.to_f(unit), unit)
   end

   def convert(unit)
     self.to_m(unit)
   end

   def inspect
     self.to_s
   end

   def to_s
     @value.to_f.to_s+@unit.to_s
   end

   def dimension
     self.class.dimension(@unit)
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
       raise Exception.new("Unknown unit: #{unit.inspect}") unless @@units.keys.include? unit
       raise Exception.new("Measure can't be converted from one dimension (#{@@units[@unit][:dimension].inspect}) to an other (#{@@units[unit][:dimension].inspect})") if @@units[@unit][:dimension]!=@@units[unit][:dimension]
       @value*@@units[@unit][:factor]/@@units[unit][:factor]
     end
   end

 end



 def Measure(value, unit)
   ::Measure.new(value, unit)
 end
