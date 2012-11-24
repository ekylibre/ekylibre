# encoding: UTF-8
require 'prawn/measurement_extensions'

class ::Numeric
  # Convert pica to pt
  def pc
    return self * 12
  end
end


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
      attr_reader :pen, :default_font

      INFOS = {
        :created_on => :CreationDate,
        :updated_on => :ModDate,
        :title => :Title,
        :subject => :Subject,
        :keywords => :Keywords,
        :author => :Author,
        :creator => :Creator,
        :producer => :Producer
      }

      # Create a document
      # @param [Hash] options The options to specify the document properties
      # @option options [TrueClass,FalseClass] :debug Activates debug mode
      # @option options [Hash] :default_font ({:name=>'Helvetica', :size=>10}) Set default font
      # @option options [String] :created_on (Time.now) Date of creation
      # @option options [String] :updated_on (Time.now) Date of update
      # @option options [String] :title Title of the whole document
      # @option options [String] :subject Subject of the document
      # @option options [String] :keywords Key words to define the document
      # @option options [String] :author Person who is the origin of the document
      # @option options [String] :creator Person who launches the print
      # @option options [String] :producer Software which generates document.
      #   This option may not be overloadable
      def initialize(options = {})
        now = Time.now
        options[:created_on] ||= now
        options[:updated_on] ||= now
        info = {}
        for key, value in options
          info[INFOS[key]] = value if INFOS[key]
        end
        @pen = Prawn::Document.new(:skip_page_creation => true, :info=>info, :compress=>true)
        @default_font = {:name=>'Helvetica', :size=>10}
        @default_font.update(options[:default_font] || {})
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


    # This module provides some methods to normalize values
    module PenHelper
      COLOR_KEYWORDS = {"black" => [0,0,0], "silver" => [192,192,192], "gray" => [128,128,128], "white" => [255,255,255], "maroon" => [128,0,0], "red" => [255,0,0], "purple" => [128,0,128], "fuchsia" => [255,0,255], "green" => [0,128,0], "lime" => [0,255,0], "olive" => [128,128,0], "yellow" => [255,255,0], "navy" => [0,0,128], "blue" => [0,0,255], "teal" => [0,128,128], "aqua" => [0,255,255], "orange" => [255,165,0], "aliceblue" => [240,248,245], "antiquewhite" => [250,235,215], "aquamarine" => [127,255,212], "azure" => [240,255,255], "beige" => [245,245,220], "bisque" => [255,228,196], "blanchedalmond" => [255,235,205], "blueviolet" => [138,43,226], "brown" => [165,42,42], "burlywood" => [222,184,35], "cadetblue" => [95,158,160], "chartreuse" => [127,255,0], "chocolate" => [210,105,30], "coral" => [255,127,80], "cornflowerblue" => [100,149,237], "cornsilk" => [255,248,220], "crimson" => [220,20,60], "darkblue" => [0,0,139], "darkcyan" => [0,139,139], "darkgoldenrod" => [184,134,11], "darkgray" => [169,169,169], "darkgreen" => [0,100,0], "darkgrey" => [169,169,169], "darkkhaki" => [189,183,107], "darkmagenta" => [139,0,139], "darkolivegreen" => [85,107,47], "darkorange" => [255,140,0], "darkorchid" => [153,50,204], "darkred" => [139,0,0], "darksalmon" => [233,150,122], "darkseagreen" => [143,188,143], "darkslateblue" => [72,61,139], "darkslategray" => [47,79,79], "darkslategrey" => [47,79,79], "darkturquoise" => [0,206,209], "darkviolet" => [148,0,211], "deeppink" => [255,20,147], "deepskyblue" => [0,191,255], "dimgray" => [105,105,105], "dimgrey" => [105,105,105], "dodgerblue" => [30,144,255], "firebrick" => [178,34,34], "floralwhite" => [255,250,240], "forestgreen" => [34,139,34], "gainsboro" => [220,220,220], "ghostwhite" => [248,248,255], "gold" => [255,215,0], "goldenrod" => [218,165,32], "greenyellow" => [173,255,47], "grey" => [128,128,128], "honeydew" => [240,255,240], "hotpink" => [255,105,180], "indianred" => [205,92,92], "indigo" => [75,0,130], "ivory" => [255,255,240], "khaki" => [240,230,140], "lavender" => [230,230,250], "lavenderblush" => [255,240,245], "lawngreen" => [124,252,0], "lemonchiffon" => [255,250,205], "lightblue" => [173,216,230], "lightcoral" => [240,128,128], "lightcyan" => [224,255,255], "lightgoldenrodyellow" => [250,250,210], "lightgray" => [211,211,211], "lightgreen" => [144,238,144], "lightgrey" => [211,211,211], "lightpink" => [255,182,193], "lightsalmon" => [255,160,122], "lightseagreen" => [32,178,170], "lightskyblue" => [135,206,250], "lightslategray" => [119,136,153], "lightslategrey" => [119,136,153], "lightsteelblue" => [176,196,222], "lightyellow" => [255,255,224], "limegreen" => [50,205,50], "linen" => [250,240,230], "mediumaquamarine" => [102,205,170], "mediumblue" => [0,0,205], "mediumorchid" => [186,85,211], "mediumpurple" => [147,112,219], "mediumseagreen" => [60,179,113], "mediumslateblue" => [123,104,238], "mediumspringgreen" => [0,250,154], "mediumturquoise" => [72,209,204], "mediumvioletred" => [199,21,133], "midnightblue" => [25,25,112], "mintcream" => [245,255,250], "mistyrose" => [255,228,225], "moccasin" => [255,228,181], "navajowhite" => [255,222,173], "oldlace" => [253,245,230], "olivedrab" => [107,142,35]}.freeze

      # Normalizes margins. It generates an array of 4 values
      # correponding to top, right, bottom and left like defined in CSS
      # @param [Float, Array] margins Margins
      # @param [Hash] options Options to build margins
      # @option options [TrueClass, FalseClass] :allow_nil Allow nil value in margins
      def normalize_margins(margins = nil, options = {})
        use_nil = (margins.nil? and options[:allow_nil])
        margins ||= 0 unless use_nil
        margins = [(use_nil ? nil : margins.to_f)] unless margins.is_a?(Array)
        margins[1] ||= margins[0]
        margins[2] ||= margins[0]
        margins[3] ||= margins[1]
        return margins
      end

      # Normalizes color to usable form. Follow the CSS standard
      # Accepted formats are: <name>, #L, #LL, #RGB, #RGBA, #RRGGBB,
      # #RRGGBBAA, rgb(R,G,B), rgba(R,G,B,A), hsl(H,S,L), hsla(H,S,L,A)
      def normalize_color(color, with_opacity = false)
        color = color.to_s.strip.downcase
        rgba = [0, 0, 0, 1]
        if color == "transparent"
          rgba = [0, 0, 0, 0]
        elsif COLOR_KEYWORDS[color]
          rgba = COLOR_KEYWORDS[color].collect{|v| v.to_f/255}
        elsif color.match(/^rgb\(\s*\d+\s*\,\s*\d+\s*\,\s*\d+\s*\)$/)
          rgba = color.split(/[\(\s\)\,]+/)[1..3].collect{|x| (x.to_f > 255 ? 255 : x.to_f < 0 ? 0 : x).to_f/255.0}
        elsif color.match(/^rgba\(\s*\d+\s*\,\s*\d+\s*\,\s*\d+\s*,\s*\d(\.\d+)?\s*\)$/)
          values = color.split(/[\(\s\)\,]+/).collect{|x| x.to_f}
          rgba = values[1..3].collect{|x| (x > 255 ? 255 : x < 0 ? 0 : x).to_f/255.0}
          rgba << (values[4] > 1 ? 1 : values[4] < 0 ? 0 : values[4])
        elsif color.match(/^rgb\(\s*\d+\%\s*\,\s*\d+\%\s*\,\s*\d+\%\s*\)$/)
          rgba = color.split(/[\(\s\)\,\%]+/)[1..3].collect{|x| (x.to_f > 100 ? 100 : x.to_f < 0 ? 0 : x).to_f / 100.0}
        elsif color.match(/^rgba\(\s*\d+\%\s*\,\s*\d+\%\s*\,\s*\d+\%\s*,\s*\d(\.\d+)?\s*\)$/)
          values = color.split(/[\(\s\)\,]+/).collect{|x| x.to_f}
          rgba = values[1..3].collect{|x| (x > 100 ? 100 : x < 0 ? 0 : x).to_f / 100.0}
          rgba << (values[4] > 1 ? 1 : values[4] < 0 ? 0 : values[4])
        elsif color.match(/^hsl\(\s*\d+\s*\,\s*\d+\%\s*\,\s*\d+\%\s*\)$/)
          h, s, l = color.split(/[\(\s\)\,\%]+/)[1..3].collect{|x| x.to_f}
          rgba = hsl_to_rgb(h, s, l)
        elsif color.match(/^hsla\(\s*\d+\s*\,\s*\d+\%\s*\,\s*\d+\%\s*,\s*\d(\.\d+)?\s*\)$/)
          values = color.split(/[\(\s\)\,]+/).collect{|x| x.to_f}
          rgba = hsl_to_rgb(values[1], values[2], values[3])
          rgba << (values[4] > 1 ? 1 : values[4] < 0 ? 0 : values[4])
        elsif color.match(/^\#[0123456789abcdef]$/)
          rgba = [(color[1..1]*2).to_i(16).to_f/255]*3
        elsif color.match(/^\#[0123456789abcdef]{2}$/)
          rgba = [color[1..2].to_i(16).to_f/255]*3
        elsif color.match(/^\#[0123456789abcdef]{3}$/)
          rgba = [(color[1..1]*2).to_i(16).to_f/255,
                  (color[2..2]*2).to_i(16).to_f/255,
                  (color[3..3]*2).to_i(16).to_f/255]
        elsif color.match(/^\#[0123456789abcdef]{4}$/)
          rgba = [(color[1..1]*2).to_i(16).to_f/255,
                  (color[2..2]*2).to_i(16).to_f/255,
                  (color[3..3]*2).to_i(16).to_f/255,
                  (color[4..4]*2).to_i(16).to_f/255]
        elsif color.match(/^\#[0123456789abcdef]{6}$/)
          rgba = [color[1..2].to_i(16).to_f/255,
                  color[3..4].to_i(16).to_f/255,
                  color[5..6].to_i(16).to_f/255]
        elsif color.match(/^\#[0123456789abcdef]{8}$/)
          rgba = [color[1..2].to_i(16).to_f/255,
                  color[3..4].to_i(16).to_f/255,
                  color[5..6].to_i(16).to_f/255,
                  color[7..8].to_i(16).to_f/255]
        else
          raise ArgumentError.new("Color format not supported: #{color.inspect}")
        end
        rgba[3] ||= 1
        string = "#{(rgba[0]*255).round.to_s(16).rjust(2,'0')}#{(rgba[1]*255).round.to_s(16).rjust(2,'0')}#{(rgba[2]*255).round.to_s(16).rjust(2,'0')}".downcase
        if with_opacity
          return string, rgba[3]
        else
          return string
        end
      end

      # Converts HSL values to RGB
      # @param h Hue (deg) in 0..360
      # @param s Saturation (%) in 0..100
      # @param l Luminosity (%) in 0..100
      def hsl_to_rgb(h, s, l)
        hp = h.to_i.modulo(360).to_f / 60.0
        s = (s > 100 ? 100 : s < 0 ? 0 : s).to_f / 100.0
        l = (l > 100 ? 100 : l < 0 ? 0 : l).to_f / 100.0
        chroma = (1 - (2*l - 1).abs) * s
        second = chroma * (1 - (hp.modulo(2) - 1).abs)
        m =  l - 0.5 * chroma
        rgb = if hp >= 5
                [chroma + m, second + m, m]
              elsif hp >= 4
                [second + m, chroma + m, m]
              elsif hp >= 3
                [m, chroma + m, second + m]
              elsif hp >= 2
                [m, second + m, chroma + m]
              elsif hp >= 1
                [second + m, m, chroma + m]
              else
                [chroma + m, m, second + m]
              end
        return rgb
      end


      # Sets the stroke and fill properties, yields and then fill and/or stroke
      # @todo Take in account the opacity like in CSS with rgba
      def paint(options={})
        @pen.save_graphics_state do
          fill_opacity, stroke_opacity = nil, nil
          # Set fill
          if fill = options.delete(:fill)
            color, fill_opacity = normalize_color(fill, true)
            @pen.fill_color(color)
          end
          # Set stroke
          if stroke = options.delete(:stroke)
            width, style, color = stroke.strip.split(/\s+/)
            width = width.gsub(/[a-z]+/, '').to_d.send(width.gsub(/[^a-z]+/, '').to_sym)
            @pen.line_width = width
            if style == "dotted"
              @pen.dash(width)
            elsif style == "dashed"
              @pen.dash(width*3) # Like in Firefox
            else
              @pen.undash
            end
            color, stroke_opacity = normalize_color(color, true)
            @pen.stroke_color(color)
          end
          transparent(fill_opacity, stroke_opacity) do
            yield if block_given?
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
      end

      def transparent(opacity, stroke_opacity = nil, &block)
        if block_given?
          opacity ||= 1
          stroke_opacity ||= opacity
          if opacity == 1 and stroke_opacity == 1
            yield
          else
            @pen.transparent(opacity, stroke_opacity) do
              yield
            end
          end
        end
      end

    end


    # Represents a page which can be continued on other pages with the same aspect
    # if the slices occupy more than a single page.
    class Page
      attr_reader :margins, :document, :width, :height, :done
      attr_accessor :debug_margin

      # Defines a page style and start a new page
      # @see Document#page
      def initialize(document, options={})
        @document = document
        @pen = document.pen
        @margins = normalize_margins(options.delete(:margins) || 15.mm)
        @debug_margin = 7
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
      # @option options [TrueClass,FalseClass] :bottom (false) Put the slice at
      #   the bottom of the page (It adds a filling slice before).
      def slice(options={}, &block)
        height = Slice.height(self, options, &block)
        # New page if there is no place on the current
        self.break! if @height-@done-@margins[2]-height < 0
        # Add spacer slice in order to put slice at the bottom
        self.slice(:height => @height-@done-@margins[2]-height, :bottom=>nil) if options[:bottom]
        # Add slice after all
        @done += Slice.new(self, options, &block).height
        return self
      end


      # Start a new page using the default settings
      # To change the settings from a page to another, it's necessary to call {#page} again.
      # @todo set default graphics state
      def break!
        @document.pen.start_new_page(:size => [@width, @height], :margin => 0)
        f = @document.default_font
        @document.pen.font(f[:name], :size=>f[:size])
        if @document.debug?
          paint(:stroke=>"0.2pt solid #00F5") do
            # @pen.rectangle([@margins[3]-@debug_margin, @height-@margins[1]+@debug_margin], self.inner_width+2*@debug_margin, self.inner_height+2*@debug_margin)
            @pen.line([0, @margins[2]], [@margins[3]-@debug_margin, @margins[2]])
            @pen.line([0, @height-@margins[0]], [@margins[3]-@debug_margin, @height-@margins[0]])
            @pen.line([@width-@margins[1]+@debug_margin, @margins[2]], [@width, @margins[2]])
            @pen.line([@width-@margins[1]+@debug_margin, @height-@margins[0]], [@width, @height-@margins[0]])
            @pen.line([@margins[3], 0], [@margins[3], @margins[2]-@debug_margin])
            @pen.line([@margins[3], @height-@margins[0]+@debug_margin], [@margins[3], @height])
            @pen.line([@width-@margins[1], 0], [@width-@margins[1], @margins[2]-@debug_margin])
            @pen.line([@width-@margins[1], @height-@margins[0]+@debug_margin], [@width-@margins[1], @height])
          end
        end
        @done = @start.to_f
        return self
      end

      # Return the width of the page inside the margins
      def inner_width
        @width - @margins[1] - @margins[3]
      end

      # Return the height of the page inside the margins
      def inner_height
        @height - @margins[0] - @margins[2]
      end

      private

      include PenHelper

    end


    # Slice is the atomic unit in the page. It is a band in the page.
    # If there is not enough space on the page, the slice is drawn on a new page.
    # A slice permits to draw: texts, images, lines, ellipse, rectangles
    class Slice
      attr_reader :margins, :height

      # Compute the maximal height of a slice
      # @return [Float] Height of the slice
      # @see Slice#initialize
      def self.height(page, options={}, &block)
        height = options[:height]
        if height.nil?
          pen = page.document.pen
          pen.transaction do
            height = Slice.new(page, options.dup, &block).height
            pen.rollback
          end
        end
        return height.to_f
      end

      # Create a slice
      # @param [Page] page The page used to print the slice
      # @param [Hash] options The options to define the slice
      # @option options [Float] :height Defines the height of the slice.
      #   If the height is nil then the slice will be resized automatically else
      #   the slice height is fixed and there is no resizing.
      # @option options [Float,Array] :margins (0) The margins to use for the slice.
      #   Negative values will make overflows on other slices.
      def initialize(page, options={}, &block)
        @page = page
        @document = @page.document
        @pen = @document.pen
        @resizing = options[:height].nil?
        @height = (resizing? ? nil : options.delete(:height).to_f)
        @margins = normalize_margins(options.delete(:margins))
        if !resizing? and @height < @margins[0]+@margins[2]
          raise ArgumentError.new("Vertical margins are too big")
        end
        if @page.inner_width < @margins[1]+@margins[3]
          raise ArgumentError.new("Horizontal margins are too big")
        end
        @boxes_stack = []
        @current_box = -1
        left, top = @page.margins[3]+@margins[3], @page.done+@margins[0]
        inner_width = @page.width-(left + @page.margins[1] + @margins[1])
        inner_height = (resizing? ? nil : @height-@margins[0]-@margins[2])
        box = self.box(:left=>left, :top=>top, :width=>inner_width, :height=>inner_height) do
          paint(:fill=>"black", :stroke=>"1pt solid black") do
            yield self if block_given?
          end
        end
        @height = box.height + @margins[0] + @margins[2] if resizing?
        if @document.debug?
          bottom = @page.height - @height - @page.done
          paint(:stroke=>"0.2pt solid #00F5") do
            @pen.line([0, bottom], [@page.margins[3]-@page.debug_margin, bottom])
            @pen.line([@page.width-@page.margins[1]+@page.debug_margin, bottom], [@page.width, bottom])
          end
        end
      end

      # A Box permits to create items relatively to the box position.
      # @param [Hash] options The options to define the box
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [Float] :width Defines the width of the zone
      # @option options [Float] :height Defines the height of the zone
      def box(options={}, &block)
        child = Box.new(:left=>options[:left], :top=>options[:top], :width=>options[:width], :height=>options[:height], :page=>@page, :parent=>current_box)
        @current_box += 1
        @boxes_stack[@current_box] = child
        yield if block_given?
        @boxes_stack.delete_at(@current_box)
        @current_box -= 1
        current_box.resize(child.top+child.height) if current_box

        if @document.debug?
          paint(:stroke=>"0.2pt solid #00F5") do
            @pen.rectangle([child.x, child.y], child.width, child.height)
            @pen.line(child.top_left, child.bottom_right)
            @pen.line(child.bottom_left, child.top_right)
          end
          paint(:fill=>"#00F5") do
            angle = 0
            @pen.font('Times-Roman', :size=>7) do
              for corner in [:top_left, :top_right, :bottom_right, :bottom_left]
                method = corner # "absolute_#{corner}"
                abso = child.send(corner) # @pen.bounds.send("absolute_#{corner}")
                @pen.text_box("(#{abso[0]}, #{abso[1]})", :at=>child.send(method), :rotate=>angle)
                angle -= 90
              end
            end
          end
        end

        return child
      end

      # Returns the current box
      def current_box
        @boxes_stack[@current_box]
      end

      def resizing?
        @resizing
      end

      # Returns the width of the slice
      def width
        @width
      end

      # Return the height of the slice (using delta)
      def height
        @height
      end


      # Insert an image in JPG or PNG
      # @param [String] file The file path of the image
      # @param [Hash] options The options to create the image
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [Float] :width Width of the rectangle
      # @option options [Float] :height Height of the rectangle
      def image(file, options = {})
        left, top = (options.delete(:left)||0), (options.delete(:top)||0)
        options[:at] = [current_box.x + left, current_box.y - top]
        options[:width] = current_box.width unless options[:width] or options[:height]
        info = @pen.image(file, options)
        current_box.resize(top + info.scaled_height)
        if @document.debug?
          paint(:stroke=>"0.2pt solid #00F5") do
            @pen.rectangle(options[:at], info.scaled_width, info.scaled_height)
          end
        end
        return self
      end


      # Draw a rectangle
      # @param [Hash] options The options to create the rectangle
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [Float] :width (current_box.width) Width of the rectangle
      # @option options [Float] :height (current_box.height) Height of the rectangle
      # @option options [Float] :radius (0) Radius length for rounded corners
      # @option options [String] :fill Color for background in CSS style
      # @option options [String] :stroke Style for border in CSS style
      def rectangle(options={})
        left, top = options.delete(:left)||0, options.delete(:top)||0
        width, height = options.delete(:width), options.delete(:height)
        radius = options.delete(:radius).to_f
        width  ||= current_box.width
        height ||= current_box.height
        point = [current_box.x + left, current_box.y - top]
        paint(options) do
          if radius.zero?
            @pen.rectangle(point, width, height)
          else
            @pen.rounded_rectangle(point, width, height, radius)
          end
        end
        current_box.resize(top + height)
        return self
      end

      # Draw a line
      # @param [Point...] points The list of point (left,top) of the line
      # @param [Hash] options The options to create the rectangle
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [String] :stroke Style for border in CSS style
      def line(*points)
        options = (points[-1].is_a?(Hash) ? points.delete_at(-1) : {})
        left, top = options.delete(:left)||0, options.delete(:top)||0
        points = points.collect do |l, t|
          current_box.resize(top+t)
          [current_box.x + left + l, current_box.y - top - t]
        end
        paint(:stroke=>options[:stroke]) do
          @pen.move_to(points.shift)
          while points.size > 0
            @pen.line_to(points.shift)
          end
        end
        return self
      end

      # Draw a polygon
      # @param [Point...] points The list of point (left,top) of the polygon
      # @param [Hash] options The options to create the poylgon
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [Float] :radius (0) Radius length for rounded corners
      # @option options [String] :fill Color for background in CSS style
      # @option options [String] :stroke Style for border in CSS style
      def polygon(*points)
        options = (points[-1].is_a?(Hash) ? points.delete_at(-1) : {})
        left, top = options.delete(:left)||0, options.delete(:top)||0
        points = points.collect do |l, t|
          current_box.resize(top+t)
          [current_box.x + left + l, current_box.y - top - t]
        end
        radius = options.delete(:radius)
        paint(options) do
          if radius.nil?
            @pen.polygon(*points)
          else
            @pen.rounded_polygon(radius.to_f, *points)
          end
        end
        return self
      end

      # Draw an ellipse.
      # The left/top position is the center of the ellipse.
      # @param [Float] radius_x The horizontal radius
      # @param [Hash] options The options to create the poylgon
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [Float] :radius_y (radius_x) The vertical radius
      # @option options [String] :fill Color for background in CSS style
      # @option options [String] :stroke Style for border in CSS style
      def ellipse(radius_x, options = {})
        left, top = options.delete(:left)||0, options.delete(:top)||0
        radius_y = options.delete(:radius_y) || radius_x
        current_box.resize(top+radius_y)
        point = [current_box.x + left, current_box.y - top]
        paint(options) do
          # @pen.ellipse(point, radius_x, radius_y)
          x, y, rx, ry = point[0], point[1], radius_x, radius_y
          lx = rx * Prawn::Graphics::KAPPA
          ly = ry * Prawn::Graphics::KAPPA
          @pen.move_to(x + rx, y)
          # Upper right hand corner
          @pen.curve_to [x,  y + ry], :bounds => [[x + rx, y + ly], [x + lx, y + ry]]
          # Upper left hand corner
          @pen.curve_to [x - rx, y], :bounds => [[x - lx, y + ry], [x - rx, y + ly]]
          # Lower left hand corner
          @pen.curve_to [x, y - ry], :bounds => [[x - rx, y - ly], [x - lx, y - ry]]
          # Lower right hand corner
          @pen.curve_to [x + rx, y], :bounds => [[x + lx, y - ry], [x + rx, y - ly]]
          @pen.move_to(x, y)
        end
        return self
      end

      # Write text
      # @param [String] string Text to display
      # @param [Hash] options The options to define the page properties
      # @option options [Symbol] :align (:left) Horizontal alignment of text
      #   (:center, :left, :right, :justify)
      # @option options [Symbol] :valign (:top) Vertical alignment of text (:center, :top, :bottom)
      # @option options [Float] :left Left position relatively to the slice or box
      # @option options [Float] :top Top position relatively to the slice or box
      # @option options [Float] :width Width of text box
      # @option options [Float] :height Height of text box
      # @option options [String] :font Set the font
      # @option options [Float] :size Set the size of the font
      # @option options [Boolean] :bold Set the text in bold face
      # @option options [Boolean] :italic Set the text in italic face
      # @option options [String] :fill Set the background color of the text box
      # @option options [String] :stroke Set the border of the text box
      # @option options [String] :radius (0) Radius length of rounded corners
      def text(string, options={})
        box_options = {}
        box_options[:document] = @pen
        left, top = (options.delete(:left)||0), (options.delete(:top)||0)
        margins = normalize_margins(options.delete(:margins))
        box_options[:at] = [current_box.x + left + margins[3], current_box.y - top - margins[0]]
        width, height = options[:width] || current_box.width, options[:height]
        radius = options.delete(:radius) || 0
        box_options[:width] = width - margins[1] - margins[3]
        box_options[:height] = options[:height] if options[:height]
        box_options[:align] = options[:align] || :left
        box_options[:valign] = options[:valign] || :top
        box = nil
        string = {:text=>string, :styles=>[]}
        string[:styles] << :bold if options[:bold]
        string[:styles] << :italic if options[:italic]
        string[:font] = options[:font] if options[:font]
        string[:size] = options[:size] if options[:size]
        string[:color] = normalize_color(options[:color]) if options[:color]
        @pen.save_graphics_state do
          @pen.save_font do
            @pen.font(options.delete(:font), :size=>options[:size]) if options[:font]
            inner_height = (options[:height].nil? ? @pen.height_of_formatted([string], box_options) : options[:height] - margins[0] - margins [2]) #
            if options[:fill] or options[:stroke]
              paint(:fill=>options.delete(:fill), :stroke=>options.delete(:stroke)) do
                if radius.zero?
                  @pen.rectangle([current_box.x + left, current_box.y - top], width, inner_height + margins[0] + margins [2])
                else
                  @pen.rounded_rectangle([current_box.x + left, current_box.y - top], width, inner_height + margins[0] + margins [2], radius)
                end
              end
              paint(:fill=>"#DDF5") do
                @pen.rectangle(box_options[:at], box_options[:width], inner_height)
              end if @document.debug?
            end
            # raise [@pen.font.send(:size), @pen.font.height, @pen.font.ascender, @pen.font.line_gap, @pen.font.descender].inspect
            # Little vertical adjustment
            box_options[:at][1] -= @pen.font.descender/2
            box = Prawn::Text::Formatted::Box.new([string], box_options)
            box.render
            current_box.resize(top + margins[0] + inner_height + margins[2])
          end
        end
        return box
      end

      # Writes a row of text cell
      # @param [Array] cells Array of cells. A cell can be a String or a Hash like
      #   {:value=>"text", :width=>50}
      # @param [Hash] options Option for the row
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [Float] :width Default width for each cell
      # @option options [Float] :stroke Default border for each cell
      # @option options [Float,Array] :margins ([2,2,0]) Default margins for each cell
      # @option cell_options [String] :value Text to display
      # @option cell_options [Symbol] :align Horizontal alignment of the text
      # @option cell_options [Symbol] :valign Vertical alignment of the text
      # @option cell_options [String] :bold Text to display
      # @option cell_options [String] :font Set the font
      # @option cell_options [String] :color Set the text color
      # @option cell_options [Float] :size Set the size of the font
      # @option cell_options [Boolean] :bold Set the text in bold face
      # @option cell_options [Boolean] :italic Set the text in italic face
      # @option cell_options [String,Array] :border Set the border of the cell
      # @option cell_options [Float,Array] :margins Margins of the cell. If a value is nil, the
      #   default value is used.
      # @option cell_options [String] :fill Set the background color of the cell
      # @option cell_options [String] :stroke Set the border of the cell
      def row(cells, options={})
        left, top = (options.delete(:left)||0), (options.delete(:top)||0)
        default_margins = normalize_margins(options.delete(:margins) || [2,2,0])
        cells = cells.collect do |x|
          (x.is_a?(Hash) ? x : {:value=>x.to_s})
        end
        for cell in cells
          string = {:text=>cell[:value].to_s}
          styles = []
          styles << :bold if cell[:bold]
          styles << :italic if cell[:italic]
          string[:styles] = styles
          string[:font] = cell[:font] if cell[:font]
          string[:size] = cell[:size] if cell[:size]
          string[:color] = normalize_color(cell[:color] || '#0')
          cell[:value] = [string]
          cell[:margins] = normalize_margins(cell.delete(:margins), :allow_nil=>true)
          default_margins.each_with_index do |length, index|
            cell[:margins][index] ||= length
          end
        end
        widthed = cells.select{|c| !c[:width].nil?}
        if widthed.count != cells.count
          unless default_width = options[:width]
            default_width = (current_box.width - widthed.inject(0){|s, c| s + c[:width]}).to_f / (cells.count - widthed.count)
          end
          for cell in cells
            cell[:width] ||= default_width
          end
        end
        max_height = 0
        shift = 0
        for cell in cells
          cell[:inner_width] = cell[:width]-cell[:margins][1]-cell[:margins][3]
          @pen.save_font do
            cell[:inner_height] = @pen.height_of_formatted(cell[:value], :width=>cell[:inner_width])
            height = cell[:margins][0] + cell[:inner_height] + cell[:margins][2]
            max_height = height if height > max_height
          end
          cell[:left] = shift
          shift += cell[:width]
        end
        for cell in cells
          cell[:inner_height] = max_height - cell[:margins][0] - cell[:margins][2]
          paint(:stroke=>cell[:stroke]||options[:stroke], :fill=>(cell[:fill] || 'transparent')) do
            @pen.rectangle([current_box.x + left + cell[:left], current_box.y - top], cell[:width], cell[:margins][0] + cell[:inner_height] + cell[:margins][2])
          end
          paint do
            @pen.formatted_text_box(cell[:value], :at=>[current_box.x + left + cell[:left] + cell[:margins][3], current_box.y - top - cell[:margins][0]], :width=>cell[:inner_width], :align=>cell[:align], :valign=>cell[:valign]||:center, :height=>cell[:inner_height])
          end
        end
        current_box.resize(top + max_height)
        return self
      end

      # Writes an numeroted list with 1 line per item.
      # @param [String] lines The text to parse and present as a list
      # @param [Hash] options The options to define the list properties
      # @option options [Float] :left (0) Left position from left paper border or parent box
      # @option options [Float] :top (0) Top position from top paper border or parent box
      # @option options [Float] :width Width of block
      # @option options [Integer] :columns (3) Number of columns
      # @option options [String] :font Name of the font used to write the list
      # @option options [Float] :size (7) Size of the font
      # @option options [Float] :spacing (10) Space betwen columns
      def list(lines, options={})
        @pen.save_font do
          nb_columns = options[:columns] || 3
          left, top = (options.delete(:left)||0), (options.delete(:top)||0)
          width = options.delete(:width) || (current_box.width - left)
          spacing = options.delete(:spacing) || 10
          col_width = (width - (nb_columns - 1) * spacing) / nb_columns
          font_size = options[:size] || 7
          if options[:font]
            @pen.font(options[:font], :size=>font_size)
          end
          alinea = font_size * 3
          interline = font_size * 0.5
          total_height =  0
          lines = lines.to_a
          for line in lines
            total_height += @pen.height_of(line, :width=>(col_width - alinea)) + interline
          end
          total_height -= interline
          col_height = (total_height / nb_columns) - interline
          if @document.debug?
            @pen.rectangle([current_box.x + left, current_box.y - top], width, col_height)
          end
          walked = 0
          lines.each_with_index do |line, index|
            Prawn::Text::Box.new((index+1).to_s+".", :at=>[current_box.x + left, current_box.y - top - walked], :width=>0.9*alinea, :align=>:right, :document=>@pen).render
            box = Prawn::Text::Box.new(line, :at=>[current_box.x + left + alinea, current_box.y - top - walked], :width=>(col_width - alinea), :align=>:justify, :size=>font_size, :document=>@pen)
            box.render
            if @document.debug?
              paint(:stoke=>"0.3pt solid #F00") do
                @pen.rectangle([current_box.x + left + alinea, current_box.y - top - walked], (col_width - alinea), box.height)
              end
            end
            walked += box.height + interline
            current_box.resize(top+walked - interline)
            if walked >= 0.97*col_height
              left += col_width + spacing
              walked = 0
            end
          end
        end
        return self
      end

      # Computes height of string
      def height_of(string, options={})
        @pen.height_of(string, options)
      end

      # @param [Hash] options The options to define the list properties
      # @option options [Symbol] :size Size of the font
      def font(name, options={}, &block)
        @pen.font(name, options, &block)
      end

      private

      include PenHelper
    end



    # Helper classes


    class Box
      attr_reader :left, :top, :width, :height, :absolute_left, :absolute_top, :parent, :page

      def initialize(options={})
        @left   = options[:left] || 0
        @top    = options[:top] || 0
        @width  = options[:width]
        @height = options[:height]
        @parent = options[:parent]
        @page   = options[:page]
        @absolute_left = @left
        @absolute_top = @top
        @resizing = @height.nil?
        if @parent
          @page ||= @parent.page
          @width  ||= @parent.width - @left
          @height ||= @parent.height - @top unless resizing?
          @absolute_left += @parent.absolute_left
          @absolute_top  += @parent.absolute_top
        end
        @height ||= 0
        raise ArgumentError.new("Option :width must be specified if no parent given.") if @width.nil?
        # raise ArgumentError.new("Option :height must be specified if no parent given.") if @height.nil?
      end

      def inspect
        # "{#{@left}:#{@top}~>#{@absolute_left}:#{@absolute_top} #{@width.round}x#{@height.round}}" # #{@parent.inspect if @parent}->
        "{#{@left}:#{@top}~>#{self.x}:#{self.y} #{@width.round}x#{@height.round}}"
      end

      def resizing?
        @resizing
      end

      # Resize the box with the new relative point if box is resizable
      # @param [Float,Array] points list of float values or point
      def resize(*points)
        tops = []
        for point in points
          if point.is_a?(Array)
            tops << point[1].to_f
          elsif point.is_a?(Numeric)
            tops << point.to_f
          else
            raise ArgumentError.new("Unexpected point type: #{point.class.name}:#{point.inspect}")
          end
        end
        if resizing?
          for top in tops
            @height = top if top > @height
          end
        end
        @parent.resize(*tops.collect{|t| t+self.top}) if @parent
        return self
      end


      # Return the absolute x value of the top-left corner
      def x
        @absolute_left
      end

      # Return the absolute y value of the top-left corner
      def y
        @page.height - @absolute_top
      end

      # Return the absolute point of the top-left corner
      def top_left
        [x, y]
      end

      # Return the absolute point of the top-right corner
      def top_right
        [x+@width, y]
      end

      # Return the absolute point of the bottom-right corner
      def bottom_right
        [x+@width, y-@height]
      end

      # Return the absolute point of the bottom-left corner
      def bottom_left
        [x, y-@height]
      end

    end


  end

end
