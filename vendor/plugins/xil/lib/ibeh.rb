class ::Numeric
  def mm
    self*72/25.4
  end
end

module Ibeh


  def self.document(writer, view=nil, &block)
    doc = Document.new(writer)
    if view
      view.instance_values.each do |k,v|
        doc.instance_variable_set("@"+k.to_s, v)
      end
    end
    doc.call(doc, block)
    doc.writer
  end

  # Default xil element
  class Element
    include ActionView::Helpers::NumberHelper
    attr_reader :writer

    @@testing = false
    
    def initialize(writer)
      @writer = writer
    end

    def testing?
      @@testing
    end
    
    def testing!(test=true)
      @@testing = test
    end

    def write(method, *args)
      @writer.send(method, *args) unless testing?
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
      variable(:font_size, 10)
      variable(:font_name, "Times")
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
      # Testing height of part
      part = Part.new(@writer, self, height||(@format[1]-@margin[0]-@margin[2]))
      part.testing!
      call(part, block)
      part.testing! false
      # Writing part
      page_break if @y-part.height-@margin[2]<0
      if options[:bottom]
        part(@y-@margin[2]-part.height)
      end
      part = Part.new(@writer, self, part.height)
      call(part, block)
      @y -= part.height
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
        table_width = total if options[:fixed]
        columns.each do |c|
          c[:offset] = l
          c[:width] = fixed ? c[:flex] : table_width*c[:flex]/total 
          l += c[:width]
        end
        part(1.mm)
        part(options[:header_height]||4.mm) do
          # set table_left, 0, :font_size=>10 do
          set :left=>table_left, :font_size=>10 do
            line [[0, 0], [table_width, 0]], :border=>{:color=>'#000', :width=>0.5}
            for c in columns
              part.resize_to(textbox(c[:title].to_s, c[:width], part.height, :left=>c[:offset], :top=>0.5.mm, :bold=>true, :align=>:center, :valign=>:middle))
              line([[c[:offset],0], [c[:offset], part.height]], :border=>{:color=>'#000', :width=>0.5})
            end
            line [[table_width, 0], [table_width, part.height]], :border=>{:color=>'#000', :width=>0.5}
            line [[0, part.height], [table_width, part.height]], :border=>{:color=>'#000', :width=>0.5}
          end
        end
        for x in collection
          part(options[:row_height]||4.mm) do
            # set table_left, 0, :font_size=>10 do
            set :left=>table_left, :font_size=>10 do
              for c in columns
                options = c[:options]||{}
                value = (x.is_a?(Hash) ? x[c[:value]] : x.instance_eval(c[:value]))
                if value.is_a? Date
                  value = ::I18n.localize(value, :format=>options[:format]||:default) if options[:format]
                  options[:align] ||= :center
                elsif value.is_a? Numeric
                  value = number_to_currency(value, :separator=>options[:separator]||',', :delimiter=>options[:delimiter]||' ', :unit=>options[:unit]||'', :precision=>options[:precision]||2) if options[:numeric]==:money
                  options[:align] ||= :right
                end                
                part.resize_to(textbox(value.to_s, c[:width], part.height, :left=>c[:offset], :top=>0.5.mm, :align=>options[:align]))
              end
              for c in columns
                line([[c[:offset],0], [c[:offset], part.height]], :border=>{:color=>'#000', :width=>0.5})
              end
              line [[table_left, part.height], [table_width, part.height], [table_width, 0], [0,0]], :border=>{:color=>'#000', :width=>0.5}
            end
          end
        end
      end
    end

    def page_break
      write(:new_page, @format, @options[:rotate]||0)
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
    attr_accessor :height, :top

    def initialize(writer, page, height)
      super writer
      @page   = page
      @height = height
      @top    = @page.y
      if @page.debug?
        x1, x2 = @page.margin[3], @page.width-@page.margin[1]
        write(:line, [[x1, @top], [x2, @top-height]], :border=>{:color=>'#cdF', :width=>5})
        write(:line, [[x2, @top], [x1, @top-height]], :border=>{:color=>'#Fdc', :width=>5})
        write(:line, [[x1, @top], [x2, @top], [x2, @top-height], [x1, @top-height], [x1, @top]], :border=>{:color=>'#888', :width=>0})
      end
    end

#     def set(left=0, top=0, env={}, &block)
#       left ||= 0
#       top ||= 0
    def set(options={}, env={}, &block)
      if options[:right]
        left = self.width-options[:right]
      else
        left = options[:left]||0
      end
      # left = @left+(options[:left]||0)
      top  = options[:top]||0
      #left, top = options[:left]||0, options[:top]||0
      left += @page.margin[3]
      write(:save_graphics_state)
      set = Set.new(@writer, @page.env.dup.merge(env), left, @top-top, self)
      call(set, block)
      write(:restore_graphics_state)
    end

    def resize_to(height, forced=false)      
      @height = height if forced or (!forced and height>@height)
    end    

    def width
      @page.width-@page.margin[1]-@page.margin[3]
    end

  end




  # Represents a <set>
  class Set < Element
    attr_accessor :part

    def initialize(writer, env, left, top, part)
      super writer
      @env  = env
      @left = left
      @top  = top
      @part = part
    end

    def variable(name, value=nil)
      @env[name] = value unless value.nil?
      @env[name]
    end

    def string_height(text, width, options={})
      @writer.get_string_height(text, width, variable(:font_name), variable(:font_size), {:italic=>options[:italic], :bold=>options[:bold]})
    end

    # def set(left=0, top=0, env={}, &block)
    def set(options={}, env={}, &block)
      if options[:right]
        left = self.width-options[:right]
      else
        left = options[:left]||0
      end
      top  = options[:top]||0
      #left, top = options[:left]||0, options[:top]||0
      write(:save_graphics_state)
      set = Set.new(@writer, @env.dup.merge(env), @left+left, @top-top, @part)
      set.font
      call(set, block)
      write(:restore_graphics_state)
    end

    def font(name=nil, size=nil, color=nil, options={})
      name = variable(:font_name, name)
      size = variable(:font_size, size)
      color = variable(:color, color)
      write(:font, name, options.merge(:size=>size, :color=>color))
    end

    def text(value, options={})
      value = value.to_s
      env = @env.dup
      face_options = {:italic=>options[:italic], :bold=>options[:bold]}
      font(options[:font], options.delete(:size), options.delete(:color), face_options)
      height = @writer.get_string_height(value, options[:width], variable(:font_name), variable(:font_size), face_options)
      if options[:right]
        left = @left+(self.width-options[:right])
      else
        left = @left+(options[:left]||0)
      end
      top  = @top-(options[:top]||0)-0.7*variable(:font_size)
      write(:text, value, :at=>[left, top], :align=>options[:align], :width=>options[:width])
      if @page.debug?
        wcross = 5
        write(:line, [[left-wcross, top], [left+wcross, top]], :border=>{:color=>'#FCC', :width=>0})
        write(:line, [[left, top-wcross], [left, top+wcross]], :border=>{:color=>'#FCC', :width=>0})
      end
      @env = env
      self.part.resize_to(height-@top+self.part.top) if options[:resize]
      return height
    end


    def textbox(value, width, height=nil, options={})
      face_options = {:italic=>options[:italic], :bold=>options[:bold]}
      # font(options[:font], options.delete(:size), options.delete(:color), face_options)
      padding = 1.mm.to_f
      left = (options[:left]||0)
      if options[:align]==:center
        left += width.to_f/2
      elsif options[:align]==:right
        left += width.to_f - padding/2
      else
        left += padding/2
      end
      h = @writer.get_string_height(value, width, variable(:font_name), variable(:font_size), face_options)
      top = (options[:top]||0)
      if options[:valign]==:middle
        top += (height.to_f - h)/2
      elsif options[:valign]==:bottom
        top += (height.to_f - h)
      else
        top += padding/2
      end
      text(value, options.merge(:left=>left, :top=>top, :width=>width))+padding
    end


    def cell(width, height, value, options={})
      font(options[:font], options.delete(:size), options.delete(:color), :italic=>options[:italic], :bold=>options[:bold])
      left = (options[:left]||0)
      if options[:align]==:center
        left += width.to_f/2
      elsif options[:align]==:right
        left += width.to_f - 0.5.mm
      else
        left += 0.5.mm
      end
      top = (options[:top]||0)
      if options[:valign]==:middle
        top += (height.to_f - variable(:font_size))/2
      elsif options[:valign]==:bottom
        top += (height.to_f - variable(:font_size))
      else
        top += 0.5.mm
      end
      rectangle(width, height, options) if options[:border]
      text value, options.merge(:left=>left, :top=>top)
    end

    def rectangle(width, height, options={})
      if options[:right]
        left = @left+(self.width-options[:right])
      else
        left = @left+(options[:left]||0)
      end
      # left = @left+(options[:left]||0)
      top  = @top-(options[:top]||0)
      write(:rectangle, left, top, width, -height, options)
    end

    def image(file, width, height, options={}, &block)
      left = options[:left]||0
      top  = options[:top]||0      
      write(:image, file, @left+left, @top-top-height, width, height)
    end

    def line(points, options={})
      write(:line, points.collect{|p| [@left+p[0], @top-p[1]]}, options)
    end






    def list(collection, options={})
      nb_columns = (options[:columns]||1).to_i
      width = options[:width]||self.width
      col_width = width/nb_columns
      face_options = {:italic=>options[:italic], :bold=>options[:bold]}
      font(options[:font], options.delete(:size), options.delete(:color), face_options)
      #font("Times", 7)
      font_size = variable(:font_size)
      alinea = font_size*4
      total_height = 0
      collection.each{|s| total_height += string_height(s, col_width-alinea)+0.1*alinea; }
      col_height = total_height.to_f/nb_columns
      left = 0
      walked = 0
      max = 0
      indice = 0
      for string in collection
        text((indice+=1).to_s+".",  :left=>left+0.6*alinea, :top=>walked, :align=>:right)
        walked += text(string, :left=>left+0.7*alinea, :top=>walked, :width=>col_width-alinea)+0.1*alinea
        # puts "WALKED: #{total_height*0.35} / #{max*0.35} / #{walked*0.35}"
        if walked>=0.97*col_height
          max = walked if walked > max
          left += col_width
          walked = 0
        end
      end
      # puts "************"
      self.part.resize_to(max+self.part.top-@top) if options[:resize]
    end







    def width
      @page.width-@page.margin[3]-@left # -@page.margin[1]
    end





  end

end
