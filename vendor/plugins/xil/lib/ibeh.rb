class ::Numeric
  def mm
    self*72/25.4
  end
end

module Ibeh
  include ActionView::Helpers::NumberHelper


  def self.document(writer, view, &block)
    doc = Document.new(writer)
    view.instance_values.each do |k,v|
      doc.instance_variable_set("@"+k.to_s, v)
    end
    doc.call(doc, block)
    doc.writer
  end

  # Default xil element
  class Element
    attr_reader :writer

    def initialize(writer)
      @writer = writer
    end

    def call(element, block=nil)
      # puts self.class.to_s+' > '+element.class.to_s
      if self!=element
        self.instance_values.each do |k,v|
          element.instance_variable_set("@"+k, v) unless element.instance_variable_defined? "@"+k
        end
      end
      if block
        block.arity < 1 ? element.instance_eval(&block) : block[element]
      end
    end
  end



  # Represents a <document>
  class Document < Element
    def page(format=:a4, options={}, &block)
      page = Page.new(@writer, format, options)
      call(page, block)
    end
  end




  # Represents a <page>
  class Page < Element
    FORMATS = {
      :a1=>[594.mm, 420.mm],
      :a2=>[420.mm, 594.mm],
      :a3=>[297.mm, 420.mm],
      :a4=>[210.mm, 297.mm],
      :a5=>[148.mm, 210.mm],
      :a6=>[105.mm, 148.mm]      
    }

    attr_reader :y, :env, :margin

    def initialize(writer, format, options)
      super writer
      @options = options
      format = FORMATS[format.to_s.lower.gsub(/[^\w]/,'').to_sym] unless format.is_a? Array
      format[0], format[1] = format[1], format[0] if @options[:orientation] == :landscape
      @format = format
      @margin = @options[:margin]||[]
      @margin[0] ||= 0
      @margin[1] ||= @margin[0]
      @margin[2] ||= @margin[0]
      @margin[3] ||= @margin[1]
      @env = {}
      variable(:font_size, 12)
      variable(:font_name, "Helvetica")
      page_break
    end
    
    def debug?
      @options[:debug]||false
    end

    def variable(name, value=nil)
      @env[name] = value unless value.nil?
      @env[name]
    end

    def part(height=nil, options={}, &block)
      height ||= @format[1]-@margin[0]-@margin[2]
      page_break if @y-height-@margin[2]<0
      part = Part.new(@writer, self, height)
      call(part, block)
      @y -= height
    end

    def table(collection, options={}, &block)
      if block_given?
        table = Table.new
        call(table, block)
        columns = table.columns
        table_left = options[:left]||0
        fixed = options[:fixed]||false
        table_width = options[:width]
        table_width ||= self.width-self.margin[1]-self.margin[3]-table_left
        total, l = 0, 0
        columns.each{ |c| total += c[:flex] }
        columns.each do |c|
          c[:offset] = l
          c[:width] = fixed ? c[:flex] : table_width*c[:flex]/total 
          l += c[:width]
        end
        part(options[:header_height]||4.mm) do
          set table_left, 0, :font_size=>10 do
            line [[0, 0], [table_width, 0]], :color=>'#777', :width=>0.2
            for c in columns
              text c[:title].to_s, :left=>c[:offset]+0.5.mm, :top=>0.5.mm, :bold=>true
              line([[c[:offset],0], [c[:offset], 4.mm]], :color=>'#777', :width=>0.2)
            end
            line [[table_width, 0], [table_width, 4.mm]], :color=>'#777', :width=>0.2
            line [[0, 4.mm], [table_width, 4.mm]], :color=>'#333', :width=>0.5
          end
        end
        for x in collection
          part(options[:row_height]||4.mm) do
            set table_left, 0, :font_size=>10 do
              for c in columns
                options = c[:options]||{}
                value = x.instance_eval(c[:value])
                if value.is_a? Date
                  value = ::I18n.localize(value, :format=>options[:format]||:default)  if options[:format]
                  options[:align] ||= :center
                elsif value.is_a? Numeric
                  value = number_to_currency(value, :separator=>options[:separator]||',', :delimiter=>options[:delimiter]||' ', :unit=>options[:unit]||'', :precision=>options[:precision]||2) if options[:format]==:money
                  options[:align] ||= :right
                end
                
                left = c[:offset]
                if options[:align]==:center
                  left += c[:width].to_f/2
                elsif options[:align]==:right
                  left += c[:width].to_f - 0.5.mm
                else
                  left += 0.5.mm
                end

                text value.to_s, :left=>left, :top=>0.5.mm, :align=>options[:align]
                line([[c[:offset],0], [c[:offset], 4.mm]], :color=>'#777', :width=>0.2)
              end
              line [[table_width, 0], [table_width, 4.mm], [0, 4.mm]], :color=>'#777', :width=>0.2
            end
          end
        end
      end
    end

    def page_break
      @writer.new_page(@format, @options[:rotate]||0)
      @y = @format[1]-@margin[0]
    end

    def width
      @format[0]
    end

    def height
      @format[1]
    end

  end



  class Table < Element
    attr_reader :columns

    def initialize
      @columns = []
    end

    def column(title, value, flex=1, options={})
      @columns << {:title=>title, :value=>value, :flex=>flex, :options=>options}
    end
  end





  # Represents a <part>
  class Part < Element

    def initialize(writer, page, height)
      super writer
      @page   = page
      @height = height
      @top    = @page.y
      if @page.debug?
        x1, x2 = @page.margin[3], @page.width-@page.margin[1]
        @writer.line [[x1, @top], [x2, @top-height]], :border=>{:color=>'#cdF', :width=>5}
        @writer.line [[x2, @top], [x1, @top-height]], :border=>{:color=>'#Fdc', :width=>5}
        @writer.line [[x1, @top], [x2, @top], [x2, @top-height], [x1, @top-height], [x1, @top]], :border=>{:color=>'#888', :width=>0}
      end
    end

    def set(left=0, top=0, env={}, &block)
      left += @page.margin[3]
      @writer.save_graphics_state
      set = Set.new(@writer, @page.env.dup.merge(env), left, @top-top)
      call(set, block)
      @writer.restore_graphics_state
    end

  end




  # Represents a <set>
  class Set < Element
    def initialize(writer, env, left, top)
      super writer
      @env  = env
      @left = left
      @top  = top
    end

    def variable(name, value=nil)
      @env[name] = value unless value.nil?
      @env[name]
    end

    def set(left=0, top=0, env={}, &block)
      @writer.save_graphics_state
      set = Set.new(@writer, @env.dup.merge(env), @left+left, @top-top)
      set.font
      call(set, block)
      @writer.restore_graphics_state
    end

    def font(name=nil, size=nil, color=nil, options={})
      name = variable(:font_name, name)
      size = variable(:font_size, size)
      color = variable(:color, color)
      @writer.font name, options.merge(:size=>size, :color=>color)
    end

    def text(value, options={}, &block)
      value = value.to_s
      env = @env.dup
      font(options[:font], options.delete(:size), options.delete(:color), :italic=>options[:italic], :bold=>options[:bold])
      left = @left+(options[:left]||0)
      top  = @top-(options[:top]||0)-0.7*variable(:font_size)
      @writer.text value, :at=>[left, top], :align=>options[:align]
      if @page.debug?
        wcross = 5
        @writer.line [[left-wcross, top], [left+wcross, top]], :border=>{:color=>'#FCC', :width=>0}
        @writer.line [[left, top-wcross], [left, top+wcross]], :border=>{:color=>'#FCC', :width=>0}
      end
      @env = env
    end

    def image(file, width, height, options={}, &block)
      left = options[:left]||0
      top  = options[:top]||0      
      @writer.image file, @left+left, @top-top-height, width, height
    end

    def line(points, options={})
      @writer.line points.collect{|p| [@left+p[0], @top-p[1]]}, {:border=>options}
    end

    def width
      @page.width-@page.margin[3]-@left # -@page.margin[1]
    end

  end

end
