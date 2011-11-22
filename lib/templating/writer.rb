# encoding: UTF-8
require 'prawn/measurement_extensions'

module Templating

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
      attr_reader :margins, :size, :document

      # Start a new page 
      def initialize(document, options={})
        @document = document
        @pen = document.pen
        @margins = options.delete(:margins) 
        @margins = [@margins] if @margins.is_a? Numeric
        @margins = [] unless @margins.is_a? Array
        @margins[0] = (@margins[0] || 15)
        @margins[1] = (@margins[1] || @margins[0])
        @margins[2] = (@margins[2] || @margins[0])
        @margins[3] = (@margins[3] || @margins[1])
        @margins.each_index do |i|
          @margins[i] = @margins[i].mm
        end
        size = options.delete(:size)
        if size.is_a?(String) or size.nil?
          @size = Prawn::Document::PageGeometry::SIZES[size || "A4"]
        elsif size.is_a? Array
          @size = [ size[0].mm, size[1].mm ]
        end
        @size = Prawn::Document::PageGeometry::SIZES["A4"] unless @size.is_a? Array
        @size = @size[0..1]
        orientation = options.delete(:orientation) || :portrait
        unless orientation == :portrait
          orientation = :landscape
          @size.reverse!
        end
        @start = self.inner_height # @size[1]- @margins[0] - @margins[2]
        self.break!
      end

      # Add a slice with the defined options
      def slice(options={}, &block)
        s = Slice.new(self)
        box = @pen.bounding_box([0, @y], :width=>inner_width, :height=>(options[:height] ? options[:height].mm : nil)) do
          # s.instance_eval(&block)
          yield s if block_given?
          s.debug_box if @document.debug?
        end
        @y -= box.height
        return self
      end

      # # Add a table as multi-slice (one slice per line)
      # def collection_table(collection, options={}, &block)
      #   self.slice(:height => 1.mm)
      #   # Header
      #   self.slice do |slice|
          
      #   end
      #   # Rows
      #   for record in collection
      #     self.slice do |slice|
      #     end        
      #   end
      #   return self
      # end

      # # Add a list with multi-column support
      # def list(options={}, &block)
      #   return self
      # end

      def break!
        @document.pen.start_new_page(:size => @size,
                                     :top_margin => @margins[0], 
                                     :right_margin => @margins[1],
                                     :bottom_margin => @margins[2],
                                     :left_margin => @margins[3])

        @pen.rectangle([0, self.inner_height], self.inner_width, self.inner_height) if @document.debug?
        @y = @start.to_f
        return self
      end

      def inner_width
        @size[0] - @margins[1] - @margins[3]
      end

      def inner_height
        @size[1] - @margins[0] - @margins[2]
      end

    end

    class Slice
      include ActionView::Helpers::NumberHelper 

      def initialize(page, options={}, &block)
        @page = page
        @document = @page.document
        @pen = @document.pen
      end

      # A Box permits to create items relatively to the box position.
      # @param [Hash] options The options to define the box
      # @option options [Float] :top Defines the distance from the top of the slice
      # @option options [Float] :left Defines the distance from the left of the slice
      def box(options={}, &block)
        box = @pen.bounding_box([options[:left].to_f, options[:top].to_f], :width=>@pen.bounds.width) do
          yield self if block_given?
          s.debug_box if @document.debug?
        end
      end
      
      
      def debug_box()
        @pen.save_graphics_state do
          @pen.stroke_color("CCCCCC")
          @pen.fill_color("CCCCCC")
          @pen.dash(1, :space=>1)
          @pen.stroke_bounds
          @pen.line(@pen.bounds.top_left, @pen.bounds.bottom_right)
          @pen.line(@pen.bounds.bottom_left, @pen.bounds.top_right)
          @pen.stroke
          angle = 0
          @pen.font('Times-Roman', :size=>7) do
            for corner in [:top_left, :top_right, :bottom_right, :bottom_left]
              method = corner # "absolute_#{corner}"
              abso = @pen.bounds.send("absolute_#{corner}")
              @pen.draw_text("(#{abso[0].round(1)}, #{abso[1].round(1)})", :at=>@pen.bounds.send(method), :rotate=>angle)
              angle -= 90
            end
          end
          @pen.undash
        end
      end

      # Returns the width of the slice
      def width
        @pen.bounds.width
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
      def text(string, options={})
        # @pen.draw_text(string, :at=>[100,100]) # , :align=>:center)
        # @pen.text(string, options)
        options = options.dup
        options[:document] = @pen
        
        box = if options.delete(:inline_format)
                array = Text::Formatted::Parser.to_array(string)
                Prawn::Text::Formatted::Box.new(array, options)
              else
                Prawn::Text::Box.new(string, options)
              end
        
        box.render
        return box
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


    end
    

    
    # Helper classes


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
