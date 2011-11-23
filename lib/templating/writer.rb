# encoding: UTF-8
require 'prawn/measurement_extensions'

module Templating

  # All the lengths are in pt (the default unit of PDF).
  module Writer

    # PDF Data as a String
    def self.generate(options={}, &block)
      doc = Document.new(options)
      yield doc if block_given?
      # doc.instance_eval(&block) if block_given?
      return doc.send(:generate)
    end

    def self.generate_file(filename, options={}, &block)
      doc = Document.new(options)
      yield doc if block_given?
      # doc.instance_eval(&block) if block_given?
      return doc.send(:generate_file, filename)
    end

    # Main class which represent the document. A document is composed of slices
    # A slice is a band in the document with a given or varying height. It's tha base unit
    # of a page.
    class Document
      attr_reader :pen

      def initialize(options = {})
        @pen = Prawn::Document.new(:skip_page_creation => true, :info=>options[:info])
        @debug = options[:debug]
      end


      # Page permits to define a style of page
      # @param [Hash] options The options to define the page properties
      # @option options [String,Array] :size The format of the page "A4" or [<width>, <height>]
      # @option options [Symbol] :orientation +:landscape+ or +:portrait+
      # @option options [Array,Float] :margins Margins presented like in CSS [<top>, <right>, <bottom>, <left>]
      def page(options = {}, &block)
        page = Page.new(self, options)
        yield page if block_given? # .instance_eval(&block)
        return self
      end

      # Declares a font family. Needed to use extra fonts in the document
      # @param [String] name Name to define the font
      # @param [String] normal_font File for normal/regular font
      # @param [String] bold_font File for bold font
      # @param [String] italic_font File for italic/oblique font
      # @param [String] bold_italic_font File for bold italic/oblique font
      def font_family(name, normal_font, bold_font, italic_font, bold_italic_font)
        @pen.font_families.update(name => {:normal=>normal_font, :bold=>bold_font, :italic_font=>italic_font, :bold_italic=>bold_italic_font})
      end

      def debug?
        @debug
      end

      protected
      
      def generate
        @pen.render
      end

      def generate_file(filename)
        @pen.render_file(filename)
      end
    end

    # Represents a page which can be continued on other pages with the same aspect
    # if the slices occupy more than a single page.
    class Page
      attr_reader :margins, :document, :width, :height, :done

      # Start a new page 
      def initialize(document, options={})
        @document = document
        @pen = document.pen
        @margins = options.delete(:margins) 
        @margins = [@margins] if @margins.is_a? Numeric
        @margins = [] unless @margins.is_a? Array
        @margins[0] = (@margins[0] || 15.mm)
        @margins[1] = (@margins[1] || @margins[0])
        @margins[2] = (@margins[2] || @margins[0])
        @margins[3] = (@margins[3] || @margins[1])
        size = options.delete(:size)
        if size.is_a?(String) or size.nil?
          size = Prawn::Document::PageGeometry::SIZES[size || "A4"]
        end
        size = Prawn::Document::PageGeometry::SIZES["A4"] unless size.is_a? Array
        size = size[0..1]
        orientation = options.delete(:orientation) || :portrait
        unless orientation == :portrait
          orientation = :landscape
          size.reverse!
        end
        @width, @height = size[0..1]
        @start = @margins[0]
        self.break!
      end

      # Add a slice with the defined options
      # @param [Hash] options The options to define the slice
      # @option options [Float] :height Default height of the slice in pt
      # @option options [TrueClass,FalseClass] :resize (false) Enable auto-resizing for larger elements
      # @option options [TrueClass,FalseClass] :bottom (false) Put the slice at the bottom of the page
      def slice(options={}, &block)
        height = Slice.height_of(self, options, &block)
        # New page if there is no place on the current
        self.break! if @height-@done-@margins[2]-height < 0
        # Add spacer slice in order to put slice at the bottom
        self.slice(:height => @height-@done-@margins[2]-height, :bottom=>nil) if options[:bottom]
        # Add slice after all
        @done += Slice.new(self, options, &block).height
        return self
      end
      
      def break!
        # @document.pen.start_new_page(:size => [@width, @height],
        #                              :top_margin => @margins[0], 
        #                              :right_margin => @margins[1],
        #                              :bottom_margin => @margins[2],
        #                              :left_margin => @margins[3])
        @document.pen.start_new_page(:size => [@width, @height], :margin => 0)
        if @document.debug?
          marg = 4
          @pen.rectangle([@margins[3]-marg, @height-@margins[1]+marg], self.inner_width+2*marg, self.inner_height+2*marg) 
        end
        @done = @start.to_f
        return self
      end

      def inner_width
        @width - @margins[1] - @margins[3]
      end

      def inner_height
        @height - @margins[0] - @margins[2]
      end

    end


    # Slice is the main unit in the page. It is a band in the page.
    class Slice
      attr_reader :height

      # Compute the height of a slice
      # @return [Float] Height of the slice
      # @see Slice#initialize
      def self.height_of(page, options={}, &block)
        height = options[:height]
        if options[:resize]
          pen = page.document.pen
          pen.transaction do
            height = Slice.new(page, options, &block).height
            pen.rollback
          end
        else
          raise ArgumentError.new("Option :height is expected when :resize is false") unless height
        end
        return height.to_f
      end
      
      def initialize(page, options={}, &block)
        @page = page
        @document = @page.document
        @pen = @document.pen
        height = options[:height]
        unless options[:resize]
          raise ArgumentError.new("Option :height is expected when :resize is false") unless height
        end
        @no_resize = options[:no_resize]
        @height = options[:height].to_f
        @boxes_stack = []
        @current_box = -1
        left, top = options[:left]||@page.margins[3], options[:top]||@page.done
        self.box(left, top, :width=>@page.width-left-@page.margins[1], :height=>(@height.zero? ? @page.height-top-@page.margins[2] : @height), :page=>@page, &block)
        
      end

      # A Box permits to create items relatively to the box position.
      # @param [Float] left (0) Left position from left paper border or parent box
      # @param [Float] top (0) Top position from top paper border or parent box
      # @param [Hash] options The options to define the box
      # @option options [Float] :width Defines the width of the zone
      # @option options [Float] :height Defines the height of the zone
      def box(left = 0, top = 0, options={}, &block)
        origin = Origin.new(left, top, options.merge(:parent=>current_box))
        if @document.debug?
          @pen.save_graphics_state do
            @pen.stroke_color("AAAADD")
            @pen.fill_color("AAAADD")
            @pen.line_width = 0.2
            @pen.rectangle([origin.x, origin.y], origin.width, origin.height)
            @pen.line(origin.top_left, origin.bottom_right)
            @pen.line(origin.bottom_left, origin.top_right)
            @pen.stroke
            angle = 0
            @pen.font('Times-Roman', :size=>7) do
              for corner in [:top_left, :top_right, :bottom_right, :bottom_left]
                method = corner # "absolute_#{corner}"
                abso = origin.send(corner) # @pen.bounds.send("absolute_#{corner}")
                @pen.draw_text("(#{abso[0].round(1)}, #{abso[1].round(1)})", :at=>origin.send(method), :rotate=>angle)
                angle -= 90
              end
            end
          end
        end
        @current_box += 1
        @boxes_stack[@current_box] = origin
        yield self if block_given?
        @boxes_stack.delete_at(@current_box)
        @current_box -= 1
      end
      
      # Returns the width of the slice
      def width
        current_box.width
      end


      # Add an image in JPG or PNG
      # @param [String] file The file path of the image
      # @param [Hash] options The options to create the image
      # @option options [Float] :width Width of the rectangle
      # @option options [Float] :height Height of the rectangle
      # @option options [Float] :top Left position of the image
      # @option options [Float] :left Left position of the image
      def image(file, options = {})
        options[:at] = [options.delete(:left) || 0, options.delete(:top) || 0]
        @pen.image(file, options)
      end


      # Draw a rectangle from point A to point B
      # @param [Hash] options The options to create the rectangle
      # @option options [Float] :width Width of the rectangle
      # @option options [Float] :height Height of the rectangle
      # @option options [Float] :radius (0) Radius length for rounded corners
      # @option options [String,Fill] :fill Style for background
      # @option options [String,Stroke] :stroke Style for border
      def rectangle(point, options={})
        width, height = options.delete(:width), options.delete(:height)
        radius = options.delete(:radius).to_f
        unless width and height
          if to = options.delete(:to)
            width  = to[0] - point[0]
            height = to[1] - point[1]
          end
        end
        width ||= @pen.bounds.width
        height ||= @pen.bounds.height
        if radius.zero?
          @pen.rectangle(point, width, height)
        else
          @pen.rectangle(point, width, height, radius)
        end
        paint(options.delete(:fill), options.delete(:stroke))
      end

      # Draw a line
      def line(*points)
        options = (points[-1].is_a?(Hash) ? points.delete_at(-1) : {})
        points.flatten!
        @pen.move_to(points.shift, points.shift)
        while points.size > 0
          @pen.line_to(points.shift, points.shift)
        end
        paint(options.delete(:fill), options.delete(:stroke))
      end

      # Draw a polygon
      # Can be rounded with :radius option
      def polygon(*points)
        options = (points[-1].is_a?(Hash) ? points.delete_at(-1) : {})
        radius = options.delete(:radius).to_f
        if radius.zero?
          @pen.polygon(points)
        else
          @pen.rounded_polygon(radius, points)
        end
        paint(options.delete(:fill), options.delete(:stroke))
      end
      
      def ellipse(center, radius_x, radius_y = radius_x)
        @pen.ellipse(center, radius_x, radius_y)
        paint(options.delete(:fill), options.delete(:stroke))
      end
      

      # Writes text in the page
      # @param [String] string Text to display
      # @param [Hash] options The options to define the page properties
      # @option options [Symbol] :align Alignment of text
      # @option options [Float] :left Left position relatively to the slice or box
      # @option options [Float] :top Top position relatively to the slice or box
      # @option options [Float] :width Width of text box
      # @option options [Float] :height Height of text box
      def text(string, options={})
        # @pen.draw_text(string, :at=>[100,100]) # , :align=>:center)
        # @pen.text(string, options)
        options = options.dup
        options[:document] = @pen
        left, top = (options.delete(:left)||0), -(options.delete(:top)||0)
        options[:at] = [left, top]
        # @pen.font(options.delete(:font)) do
        box = if options.delete(:inline_format)
                array = Text::Formatted::Parser.to_array(string)
                Prawn::Text::Formatted::Box.new(array, options)
              else
                Prawn::Text::Box.new(string, options)
              end
        box.render
        # @pen.bounds.height = if @pen.bounds.height < box.height - top
        # end
        return box
      end

      # Computes height of string
      def height_of(string, options={})
        @pen.height_of(string, options)
      end

      # Writes an numeroted list with 1 line per item.
      # @param [String] lines The text to parse and present as a list
      # @param [Hash] options The options to define the list properties
      # @option options [Symbol] :columns Number of columns
      def list(lines, options={})
        # nb_columns = (options[:columns]||1).to_i
        # width = options[:width]||self.width
        # col_width = width/nb_columns
        # # face_options = {:italic=>options[:italic], :bold=>options[:bold]}
        # # font(options[:font], options.delete(:size), options.delete(:color), face_options)
        # font_size = 7 # variable(:font_size)
        # alinea = font_size*4
        # total_height = 0
        # for s in lines
        #   total_height += string_height(s, col_width - alinea) + 0.1*alinea; 
        # end
        # col_height = total_height.to_f/nb_columns
        # left = 0
        # walked = 0
        # max = 0
        # indice = 0
        # for string in lines
        #   text((indice+=1).to_s+".",  :left=>left+0.6*alinea, :top=>walked, :align=>:right)
        #   walked += text(string, :left=>left+0.7*alinea, :top=>walked, :width=>col_width - alinea) + 0.1*alinea
        #   # puts "WALKED: #{total_height*0.35} / #{max*0.35} / #{walked*0.35}"
        #   if walked>=0.97*col_height
        #     max = walked if walked > max
        #     left += col_width
        #     walked = 0
        #   end
        # end
        # # puts "************"
        # # self.part.resize_to(max+self.part.top-@top) if options[:resize]
      end



      protected

      def paint(fill=nil, stroke=nil)
        # Set fill
        if fill
          fill = Fill.new(fill) 
          if fill.gradient?
            @pen.fill_gradient(point, width, height, fill.color, fill.color2)
          else
            @pen.fill_color = fill.color            
          end
        end
        # Set stroke
        if stroke
          stroke = Stroke.new(stroke) 
          if stroke.gradient?
            @pen.stroke_gradient(point, width, height, stroke.color, stroke.color2)
          else
            @pen.stroke_color = stroke.color            
          end
          @pen.dash(*stroke.dash_options)
          @pen.line_width = stroke.width(@page.inner_width)
        end
        # Paint
        if fill and stroke
          @pen.fill_and_stroke
        elsif fill
          @pen.fill
        elsif stroke
          @pen.stroke
        end        
      end

      private


      def current_box
        @boxes_stack[@current_box]
      end

    end
    

    
    # Helper classes

    
    class Origin
      attr_reader :left, :top, :width, :height, :absolute_left, :absolute_top, :parent, :page
      
      def initialize(left, top, options={})
        @left = left
        @top = top
        @width = options[:width]
        @height = options[:height]
        @parent = options[:parent]
        @page = options[:page]
        @absolute_left = @left
        @absolute_top = @top
        if @parent
          @page ||= @parent.page
          @width  ||= @parent.width - @left
          @height ||= @parent.height - @top
          @absolute_left += @parent.left
          @absolute_top  += @parent.top
        end
        raise ArgumentError.new("Option :width must be specified if no parent given.") if @width.nil?
        raise ArgumentError.new("Option :height must be specified if no parent given.") if @height.nil?
      end

      def x
        @absolute_left
      end

      def y
        @page.height - @absolute_top
      end

      def top_left
        [x, y]
      end

      def top_right
        [x+@width, y]
      end

      def bottom_right
        [x+@width, y-@height]
      end

      def bottom_left
        [x, y-@height]
      end

    end



    class Fill

      def initialize(*args)
      end

    end

    class Stroke
      attr_reader :width, :style
      
      def initialize(*args)
        if args.size == 1 and args[0].is_a?(String)
          expr = args[0].split(" ")
          @width = Stoke.string_to_measure(expr[0])
          @style = 0
          @color = 0
            
        else
          raise Exception.new("Unknown stroke")
        end
      end

      def self.string_to_measure(string, nvar)
        string = string.to_s
        m = if string.match(/\-?\d+(\.\d+)?mm/)
              string[0..-3]+'.mm'
            elsif string.match(/\-?\d+(\.\d+)?\%/)
              string[0..-2].to_f == 100 ? "#{nvar}.width" : (string[0..-2].to_f/100).to_s+"*#{nvar}.width"
            elsif string.match(/\-?\d+(\.\d+)?/)
              string
            else
            " (0) "
            end
        m = '('+m+')' if m.match(/^\-/)
        return m
      end

      
    end


  end

end
