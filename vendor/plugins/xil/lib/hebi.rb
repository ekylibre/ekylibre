require 'bigdecimal'
require 'zlib'
require 'iconv'

class ::Object

  def to_pdf(in_content_stream=false)
    case self
    when NilClass   then "null"
    when TrueClass  then "true"
    when FalseClass then "false"
    when Numeric    then String(self)
    when Array
      "[" << self.map { |e| e.to_pdf(in_content_stream) }.join(' ') << "]"
    when Time
      obj = self.strftime("D:%Y%m%d%H%M%S%z").chop.chop + "'00'"
      obj = obj.gsub(/[\\\n\(\)]/) { |m| "\\#{m}" }
      "(#{obj})"
    when String
#      obj = "\xFE\xFF" + self.unpack("U*").pack("n*") unless in_content_stream
#      "<" << obj.unpack("H*").first << ">"
      self.to_s
    when Symbol
       if (obj = self.to_s) =~ /\s/
         raise Exception.new("A PDF Name cannot contain whitespace")
       else
         "/" << obj
       end
    when Hash
      output = "\<\<"
      self.each do |k,v|
        unless String === k || Symbol === k
          raise Exception.new("A PDF Dictionary must be keyed by names")
        end
        output << k.to_sym.to_pdf(in_content_stream) << " " <<
                  v.to_pdf(in_content_stream)
      end
      output << "\>\>"
    when Hebi::Reference
      self.to_s
    when Hebi::Stream
      self.to_s
    else
      raise Exception.new("This object cannot be serialized to PDF (#{self.class.to_s})")
    end     
  end

end


# Hebi is a "japanese" snake (weighty but fast and nibble)
module Hebi

  # Reference to en object
  class Reference
    def initialize(id, complement=0)
      @id, @complement = id, complement
    end

    def to_s
      @id.to_s+' '+@complement.to_s+' R'
    end

    def id
      @id
    end
  end


  # General Stream 
  class Stream
    def initialize(data)
      @data = data
    end

    def to_s
      "stream\n"+@data.to_s+"\nendstream"
    end    
  end


  # Document
  class Document
    VERSION = '0.1'
    PDF_VERSION = "1.3"
    LAYOUTS = [:SinglePage, :OneColumn, :TwoColumnLeft, :TwoColumnRight]
    ZOOMS = {:page=>[:Fit], :width=>[:FitH, nil], :height=>[:FitV, nil] }
    @@win_ansi_mapping = { 0x20AC=>0x80, 0x201A=>0x82, 0x0192=>0x83, 0x201E=>0x84, 0x2026=>0x85, 0x2020=>0x86, 0x2021=>0x87, 0x02C6=>0x88, 0x2030=>0x89, 0x0160=>0x8A, 0x2039=>0x8B, 0x0152=>0x8C, 0x017D=>0x8E, 0x2018=>0x91, 0x2019=>0x92, 0x201C=>0x93, 0x201D=>0x94, 0x2022=>0x95, 0x2013=>0x96, 0x2014=>0x97, 0x02DC=>0x98, 0x2122=>0x99, 0x0161=>0x9A, 0x203A=>0x9B, 0x0152=>0x9C, 0x017E=>0x9E, 0x0178=>0x9F }

    attr_accessor :title, :keywords, :creator, :author, :subject, :zoom, :layout
    attr_reader :fonts, :available_fonts, :compress, :encoding, :ic

    def initialize(options={})
      @encoding = options[:encoding]
      # @ic = Iconv.new('ISO-8859-1', @encoding) if @encoding
      @ic = Iconv.new('UTF-8', @encoding) if @encoding
      @pages = []
      @page = -1
      @aliases = {}
      @fonts = {}
      @images = {}
      @producer = self.class.to_s+' '+VERSION
      
      @available_fonts={
        'courier'               => {:type=>:core, :base=>:'Courier', :encoding=>:WinAnsiEncoding, :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
        'courier-bold'          => {:type=>:core, :base=>:'Courier-Bold', :encoding=>:WinAnsiEncoding, :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
        'courier-italic'        => {:type=>:core, :base=>:'Courier-Oblique', :encoding=>:WinAnsiEncoding, :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
        'courier-bold-italic'   => {:type=>:core, :base=>:'Courier-BoldOblique', :encoding=>:WinAnsiEncoding, :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
        'helvetica'             => {:type=>:core, :base=>:'Helvetica', :encoding=>:WinAnsiEncoding, :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500]},
        'helvetica-bold'        => {:type=>:core, :base=>:'Helvetica-Bold', :encoding=>:WinAnsiEncoding, :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556]},
        'helvetica-italic'      => {:type=>:core, :base=>:'Helvetica-Oblique', :encoding=>:WinAnsiEncoding, :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500]},
        'helvetica-bold-italic' => {:type=>:core, :base=>:'Helvetica-BoldOblique', :encoding=>:WinAnsiEncoding, :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556]},
        'times'                 => {:type=>:core, :base=>:'Times-Roman', :encoding=>:WinAnsiEncoding, :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 408, 500, 500, 833, 778, 180, 333, 333, 500, 564, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 564, 564, 564, 444, 921, 722, 667, 667, 722, 611, 556, 722, 722, 333, 389, 722, 611, 889, 722, 722, 556, 722, 667, 556, 611, 722, 722, 944, 722, 722, 611, 333, 278, 333, 469, 500, 333, 444, 500, 444, 500, 444, 333, 500, 500, 278, 278, 500, 278, 778, 500, 500, 500, 500, 333, 389, 278, 500, 500, 722, 500, 500, 444, 480, 200, 480, 541, 350, 500, 350, 333, 500, 444, 1000, 500, 500, 333, 1000, 556, 333, 889, 350, 611, 350, 350, 333, 333, 444, 444, 350, 500, 1000, 333, 980, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 200, 500, 333, 760, 276, 500, 564, 333, 760, 333, 400, 564, 300, 300, 333, 500, 453, 250, 333, 300, 310, 500, 750, 750, 750, 444, 722, 722, 722, 722, 722, 722, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 722, 722, 722, 722, 722, 722, 564, 722, 722, 722, 722, 722, 722, 556, 500, 444, 444, 444, 444, 444, 444, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 564, 500, 500, 500, 500, 500, 500, 500, 500]},
        'times-bold'            => {:type=>:core, :base=>:'Times-Bold', :encoding=>:WinAnsiEncoding, :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 555, 500, 500, 1000, 833, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 930, 722, 667, 722, 722, 667, 611, 778, 778, 389, 500, 778, 667, 944, 722, 778, 611, 778, 722, 556, 667, 722, 722, 1000, 722, 722, 667, 333, 278, 333, 581, 500, 333, 500, 556, 444, 556, 444, 333, 500, 556, 278, 333, 556, 278, 833, 556, 500, 556, 556, 444, 389, 333, 556, 500, 722, 500, 500, 444, 394, 220, 394, 520, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 1000, 350, 667, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 220, 500, 333, 747, 300, 500, 570, 333, 747, 333, 400, 570, 300, 300, 333, 556, 540, 250, 333, 300, 330, 500, 750, 750, 750, 500, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 778, 778, 778, 778, 778, 570, 778, 722, 722, 722, 722, 722, 611, 556, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 500, 556, 500]},
        'times-italic'          => {:type=>:core, :base=>:'Times-Italic', :encoding=>:WinAnsiEncoding, :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 420, 500, 500, 833, 778, 214, 333, 333, 500, 675, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 675, 675, 675, 500, 920, 611, 611, 667, 722, 611, 611, 722, 722, 333, 444, 667, 556, 833, 667, 722, 611, 722, 611, 500, 556, 722, 611, 833, 611, 556, 556, 389, 278, 389, 422, 500, 333, 500, 500, 444, 500, 444, 278, 500, 500, 278, 278, 444, 278, 722, 500, 500, 500, 500, 389, 389, 278, 500, 444, 667, 444, 444, 389, 400, 275, 400, 541, 350, 500, 350, 333, 500, 556, 889, 500, 500, 333, 1000, 500, 333, 944, 350, 556, 350, 350, 333, 333, 556, 556, 350, 500, 889, 333, 980, 389, 333, 667, 350, 389, 556, 250, 389, 500, 500, 500, 500, 275, 500, 333, 760, 276, 500, 675, 333, 760, 333, 400, 675, 300, 300, 333, 500, 523, 250, 333, 300, 310, 500, 750, 750, 750, 500, 611, 611, 611, 611, 611, 611, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 667, 722, 722, 722, 722, 722, 675, 722, 722, 722, 722, 722, 556, 611, 500, 500, 500, 500, 500, 500, 500, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 675, 500, 500, 500, 500, 500, 444, 500, 444]},
        'times-bold-italic'     => {:type=>:core, :base=>:'Times-BoldItalic', :encoding=>:WinAnsiEncoding, :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 389, 555, 500, 500, 833, 778, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 832, 667, 667, 667, 722, 667, 667, 722, 778, 389, 500, 667, 611, 889, 722, 722, 611, 722, 667, 556, 611, 722, 667, 889, 667, 611, 611, 333, 278, 333, 570, 500, 333, 500, 500, 444, 500, 444, 333, 500, 556, 278, 278, 500, 278, 778, 556, 500, 500, 500, 389, 389, 278, 556, 444, 667, 500, 444, 389, 348, 220, 348, 570, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 944, 350, 611, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 389, 611, 250, 389, 500, 500, 500, 500, 220, 500, 333, 747, 266, 500, 606, 333, 747, 333, 400, 570, 300, 300, 333, 576, 500, 250, 333, 300, 300, 500, 750, 750, 750, 500, 667, 667, 667, 667, 667, 667, 944, 667, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 722, 722, 722, 722, 722, 570, 722, 722, 722, 722, 722, 611, 611, 500, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 444, 500, 444]},
        'symbol'                => {:type=>:core, :base=>:'Symbol', :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 713, 500, 549, 833, 778, 439, 333, 333, 500, 549, 250, 549, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 549, 549, 549, 444, 549, 722, 667, 722, 612, 611, 763, 603, 722, 333, 631, 722, 686, 889, 722, 722, 768, 741, 556, 592, 611, 690, 439, 768, 645, 795, 611, 333, 863, 333, 658, 500, 500, 631, 549, 549, 494, 439, 521, 411, 603, 329, 603, 549, 549, 576, 521, 549, 549, 521, 549, 603, 439, 576, 713, 686, 493, 686, 494, 480, 200, 480, 549, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 750, 620, 247, 549, 167, 713, 500, 753, 753, 753, 753, 1042, 987, 603, 987, 603, 400, 549, 411, 549, 549, 713, 494, 460, 549, 549, 549, 549, 1000, 603, 1000, 658, 823, 686, 795, 987, 768, 768, 823, 768, 768, 713, 713, 713, 713, 713, 713, 713, 768, 713, 790, 790, 890, 823, 549, 250, 713, 603, 603, 1042, 987, 603, 987, 603, 494, 329, 790, 790, 786, 713, 384, 384, 384, 384, 384, 384, 494, 494, 494, 494, 0, 329, 274, 686, 686, 686, 384, 384, 384, 384, 384, 384, 494, 494, 494, 0]},
        'zapfdingbats'          => {:type=>:core, :base=>:'ZapfDingbats', :char_widths=>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 278, 974, 961, 974, 980, 719, 789, 790, 791, 690, 960, 939, 549, 855, 911, 933, 911, 945, 974, 755, 846, 762, 761, 571, 677, 763, 760, 759, 754, 494, 552, 537, 577, 692, 786, 788, 788, 790, 793, 794, 816, 823, 789, 841, 823, 833, 816, 831, 923, 744, 723, 749, 790, 792, 695, 776, 768, 792, 759, 707, 708, 682, 701, 826, 815, 789, 789, 707, 687, 696, 689, 786, 787, 713, 791, 785, 791, 873, 761, 762, 762, 759, 759, 892, 892, 788, 784, 438, 138, 277, 415, 392, 392, 668, 668, 0, 390, 390, 317, 317, 276, 276, 509, 509, 410, 410, 234, 234, 334, 334, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 732, 544, 544, 910, 667, 760, 760, 776, 595, 694, 626, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 894, 838, 1016, 458, 748, 924, 748, 918, 927, 928, 928, 834, 873, 828, 924, 924, 917, 930, 931, 463, 883, 836, 836, 867, 867, 696, 696, 874, 0, 874, 760, 946, 771, 865, 771, 888, 967, 888, 831, 873, 927, 970, 918, 0]}
      }
    end

    
    

    def new_page(format=[], rotate=0)
      # format = Xil::StyleFORMATS[format.to_s.lower.gsub(/[^\w]/,'').to_sym] unless format.is_a? Array
      error('Parameter format must be an array') unless format.is_a? Array
      format[0] ||= 1000.0
      error('Parameter format can only contains numeric values') unless [Integer, Float, BigDecimal, Fixnum].include? format[0].class
      format[1] ||= format[0]*1.414
      @pages ||= []
      @page = @pages.size
      rotate = 90*(rotate.to_f/90).round
      @pages << {:format=>format, :operations=>[], :rotate=>rotate}
    end

    def page(number=nil)
      @pages[number||@page]
    end

    def alias(key, value)
      @aliases[key] = value
    end

    def image(file, x, y, w=nil, h=nil, params={})
      self.new_page if @page<0
      if @images[file].nil?
        error("File does not exists (#{file.inspect})") unless File.exists? file
        @images[file] = Hebi::Image.new(file, ('I'+@images.size.to_s).to_sym)
      end
      image = @images[file]
      if w and h.nil?
        h = w*image.height/image.width
      elsif w.nil? and h
        w = h*image.width/image.height
      elsif w.nil? and h.nil?
        h = image.height.to_f/4
        w = image.width.to_f/4
      end
      x ||= 0
      y ||= 0 #= page[:format][1]-(y||0)-h
      self.save_graphics_state
      self.concatenate_matrix(w, 0, 0, h, x, y)
      self.invoke_xobject(image.name)
      self.restore_graphics_state
    end

    def line(points, params={})
      self.new_page if @page<0
      error("Unvalid list of point") unless points.is_a? Array
      points.each{|p| error("Unvalid point: #{p.inspect}") unless is_a_point? p}
      border = params[:border]||{}
      self.set_line(border)
      self.move_to(points[0])
      points[1..-1].each{|point| self.line_to(point)}
      self.stroke(false)
    end

    def rectangle(x, y, width, height, params={})
      self.new_page if @page<0
      border = params[:border]||{}
      self.set_line(border)
      self.append_rectangle(x, y, width, height)
      self.stroke(false)      
    end

    def box(x, y, width, height, text=nil, params={}, page=nil)
      self.new_page if @page<0
      params[:font] ||= {}
      params[:font][:family] ||= 'Times'
      params[:font][:bold]   ||= false
      params[:font][:italic] ||= false
      # get_font(params[:font][:family], params[:font][:bold], params[:font][:italic])
      #      @pages[page||@page][:operations] << {:name=>:box, :args=>params}
      border = params[:border]||{}
      background = params[:background]
      x ||= 0
      y ||= 0
      self.set_fill_color(background) unless background.nil?
      self.set_line(border) unless border.empty?
      unless border.empty? and background.nil?
        self.append_rectangle(x, y, width, height)
        self.paint(!background.nil?, !border.empty?)
      end
      if text
        self.set_fill_color params[:font][:color]
        self.font(params[:font][:family], :bold=>params[:font][:bold], :italic=>params[:font][:italic], :size=>params[:font][:size]||12)
        self.begin_text_object
        self.move_text_position(x,y)
        self.show_text(text)
        self.end_text_object
      end
    end

    def text(string, options={})
      at = options[:at]||[]
      self.begin_text_object
#      self.move_text_position(at[0]||0, at[1]||0)
#      self.show_text(string)
      self.show_text_at(string, at[0]||0, at[1]||0, options[:align])
      self.end_text_object
    end

    def font(name, options={})
      self.new_page if @page<0
      label = name.downcase+(options[:bold] ? '-bold' : '')+(options[:italic] ? '-italic' : '')
      if @fonts[label].nil?
        error("Unavailable font: #{label}") if @available_fonts[label].nil?
        @fonts[label] = @available_fonts[label]
        @fonts[label][:name] = ('F'+@fonts.size.to_s).to_sym
      end
      self.select_font(@fonts[label][:name], options[:size])
      self.set_fill_color(options[:color]) if options[:color]
    end

    # Register all the ContentStream operations if the method exists
    def method_missing(method_name, *args)
      if Hebi::ContentStream.method_defined? method_name
        # page = args.delete_at(-1) if args[-1].is_a? Integer
        self.new_page if @page<0
        @pages[@page][:operations] << {:name=>method_name, :args=>args}
      else
        raise Exception.new("Unknown method for #{self.class.to_s} (#{method_name.inspect})")
      end
      self
    end

    def generate(options={})
      yield self if block_given?
      self.new_page if @page<0
      # puts @pages.inspect
      pdf_data = build
      if options[:file]
        open(options[:file],'wb') do |f|
          f.write(pdf_data)
        end
      else
        return pdf_data
      end
    end

    def error(message, nature=nil)
      raise Exception.new("#{self.class.to_s} error: #{message}")
    end

    def escape(string)
      raise Exception.new("Unvalid String to escape: #{string.inspect}") unless string.is_a? String
      text = string
      text = @ic.iconv(text) if @encoding
      text = text.to_s.unpack("U*").collect{ |i| (i<=255 ? i : @@win_ansi_mapping[codepoint]||63) }.pack("C*")
      '('+text.gsub('\\','\\\\').gsub('(','\\(').gsub(')','\\)').gsub("\r",'\\r')+')'
    end

    def defined_font(name)
      (@fonts.detect{|key, font| font[:name] == name}||[])[1]
    end

    private

    def build(compress=false)
      @compress = compress
      @objects = [0]
      @objects_count = 0
      @now = Time.now
      # Resources
      resources_ref = build_resources
      # Pages
      pages_ref, first_page_ref = build_pages(resources_ref)
      # Info
      info_ref = build_info
      # Catalog
      catalog_ref = build_catalog(pages_ref, @pages[0][:reference])
      # Built of the complete document
      pdf = "%PDF-#{PDF_VERSION}\n\n"
      xref  = "xref\n"
      xref += "0 #{(@objects_count+1).to_s}\n"
      xref += "0000000000 65535 f \n"
      for i in 1..@objects_count
        xref += sprintf('%010d 00000 n ', pdf.length)+"\n"
        pdf += i.to_s+" 0 obj\n"
        pdf += @objects[i]
        pdf += "endobj\n"
        pdf += "\n\n" unless @compress
      end
      length = pdf.length
      pdf += xref
      pdf += "trailer\n"
      trailer = {:Size=>@objects_count+1, :Root=>catalog_ref}
      trailer[:Info] = info_ref unless info_ref.nil?
      pdf += trailer.to_pdf+"\n"
      pdf += "startxref\n"
      pdf += length.to_s+"\n"
      pdf += "%%EOF\n"
      return pdf
    end

    def build_info
      info = { :CreationDate => @now, :ModDate => @now }
      info[:Producer] = escape(@producer) unless @producer.nil?
      info[:Title]    = escape(@title) unless @title.nil?
      info[:Subject]  = escape(@subject) unless @subject.nil?
      info[:Author]   = escape(@author) unless @author.nil?
      info[:Keywords] = escape(@keywords) unless @keywords.nil?
      info[:Creator]  = escape(@creator) unless @creator.nil?      
      new_object(info)
    end

    def build_resources
      # Build fonts objects
      fonts = {}
      for key, font in @fonts
        dict = {:Type=>:Font, :Name=>font[:name]}
        if font[:type] == :core
          dict[:Subtype] = :Type1
          dict[:BaseFont] = font[:base]
          dict[:Encoding] = font[:encoding] if font[:encoding]
        else
          error("Unsupported type of font: #{font[:type].inspect}")
        end
        fonts[font[:name]] = new_object(dict)
      end
      # Build images objects
      images = {}
      for key, image in @images
        images[image.name] = new_object do |lines|
          dict = {:Type=>:XObject, :Subtype=>:Image, :Width=>image.width, :Height=>image.height}
          if image.color_space==:Indexed
            dict[:ColorSpace] = [:Indexed, :DeviceRGB, image.palette.length/3-1, new_stream_object(image.palette)]
          else
            dict[:ColorSpace] = image.color_space
            dict[:Decode] = [1, 0, 1, 0, 1, 0, 1, 0] if image.color_space==:DeviceCMYK
          end
          dict[:BitsPerComponent] = image.bits
          dict[:DecodeParms] = image.parms if image.parms
          dict[:Mask]   = image.mask if image.mask
          dict[:Filter] = image.filter if image.filter
          dict[:Length] = image.data.length
          lines << dict
          lines << Stream.new(image.data)
        end
      end
      # Resource object
      new_object({:ProcSet=> [:PDF, :Text, :ImageB, :ImageC, :ImageI], :Font=>fonts, :XObject=>images})
    end

    def build_catalog(pages_ref, first_page=nil)
      catalog = {:Type=>:Catalog, :Pages=>pages_ref}
      if first_page and not zoom.nil?
        catalog[:OpenAction] = [first_page]
        catalog[:OpenAction] += if ZOOMS.keys.include? @zoom
                                  ZOOMS[@zoom]
                                elsif @zoom.is_a? Numeric
                                  [:XYZ, nil, nil, @zoom.to_f/100]
                                else
                                  ZOOMS[:page]
                                end
      end
      catalog[:PageLayout] = :OneColumn unless LAYOUTS.include? @layout
      new_object(catalog)
    end

    # Build the pages, page, content objects
    # TODO: Use balanced trees to optimize performance of viewer applications
    def build_pages(resources_ref)
      pages = []
      pages_ref = new_object
      for page in @pages
        # Page content stream
        stream = ContentStream.new(self)
        for operation in page[:operations]
          stream.send operation[:name], *operation[:args]
        end
        # Page
        dict = {:Type=>:Page, :Parent=>pages_ref, # Required
          :MediaBox=>[0, 0, page[:format][0], page[:format][1]], # Required
          :Resources=>resources_ref, # Required
          :Contents=>new_stream_object(stream.to_s)}
        dict[:Rotate] = page[:rotate] if page[:rotate] != 0
        pages << new_object(dict)
      end
      # Pages root
      dict = {:Type=>:Pages, :Kids=>pages, :Count=>pages.size}
      return new_object(dict, pages_ref)
    end

    # Create a new object
    def new_object(data=nil, reference=nil)
      if reference.nil?
        @objects_count += 1
        object_number = @objects_count
        @objects[object_number] = ''
      elsif reference.is_a? Hebi::Reference
        object_number = reference.id
      else
        raise Exception.new("Only Hebi::Reference can be used as parameter")
      end
      if block_given?
        lines = []
        yield lines
        lines.each do |item|
          @objects[object_number] += item.to_pdf+"\n"
        end
      elsif not data.nil?
        @objects[object_number] += data.to_pdf+"\n"
      end
      return reference||Hebi::Reference.new(object_number)
    end

    # Create an object with stream
    def new_stream_object(stream)
      dict = {}
      if @compress
        dict[:Filter] = :FlateDecode
        stream = Zlib::Deflate.deflate(stream)
      end
      dict[:Length] = stream.to_s.length
      new_object do |lines|
        lines << dict
        lines << Hebi::Stream.new(stream)
      end
    end

    def is_a_point?(p)
      return false unless p.is_a? Array
      return false if p.size != 2
      begin
        p[0], p[1] = p[0].to_f, p[1].to_f
      rescue
        return false
      end
      return true
    end

  end




  # Image (JPG or PNG)
  class Image
    JPEG_COLOR_SPACES = [nil, :DeviceGray, nil, :DeviceRGB, :DeviceCMYK]
    JPEG_SOF_BLOCKS = %W(\xc0 \xc1 \xc2 \xc3 \xc5 \xc6 \xc7 \xc9 \xca \xcb \xcd \xce \xcf)
    JPEG_APP_BLOCKS = %W(\xe0 \xe1 \xe2 \xe3 \xe4 \xe5 \xe6 \xe7 \xe8 \xe9 \xea \xeb \xec \xed \xee \xef)
    PNG_COLOR_SPACES  = [:DeviceGray, nil, :DeviceRGB, :Indexed]

    attr_reader :height, :width, :color_space, :bits, :name, :data, :filter
    attr_reader :palette, :pixel_bytes, :transparency, :parms, :mask

    def initialize(file, name)
      extensions = {'jpeg'=>'jpeg', 'jpg'=>'jpeg', 'png'=>'png'}    
      extension = file.split('.')[-1]
      error("Image type not supported: #{extension}, (Supported: #{extensions.keys.join(', ')})") unless extensions.keys.include? extension
      @nature = extensions[extension]
      @name = name
      send("initialize_"+@nature, file)
    end

    private

    # Process a new JPG image
    #
    # <tt>:file</tt>:: A string containing a full PNG file
    #
    def initialize_jpeg(file)
      info = {}
      data = nil
      File.open(file, "rb") do |f|
        data = f.read
      end
      data = StringIO.new(data.dup)
      channels = nil
      c_marker = "\xff" # Section marker.
      data.read(2) # Skip the first two bytes of JPEG identifier.
      loop do
        marker, code, length = data.read(4).unpack('aan')
        raise "JPEG marker not found!" if marker != c_marker
        
        if JPEG_SOF_BLOCKS.include?(code)
          @bits, @height, @width, @channels = data.read(6).unpack("CnnC")
          # info[:BitsPerComponent], info[:Height], info[:Width], channels = data.read(6).unpack("CnnC")
          break
        end
        
        buffer = data.read(length - 2)
      end
      @color_space = JPEG_COLOR_SPACES[@channels]
      raise Exception.new("JPG uses an unsupported number of channels") if @color_space.nil?
      @filter = :DCTDecode
      @decode = [1, 0, 1, 0, 1, 0, 1, 0] if @color_space==:DeviceCMYK
      File.open(file, "rb") { |f| data = f.read }
      @data   = data
    end
    
    # Initialize a PNG file
    def initialize_png(file)
      f=open(file,'rb')
      error('Not a PNG file: '+file) unless f.read(8)==137.chr+'PNG'+13.chr+10.chr+26.chr+10.chr
      f.read(4)
      error('Incorrect PNG file: '+file) if f.read(4)!='IHDR'
      @width  = freadint(f)
      @height = freadint(f)
      @bits   = f.read(1)[0]
      error('16-bit depth not supported: '+file) if @bits>8
      @pixel_bytes=f.read(1)[0]
      @color_space = PNG_COLOR_SPACES[@pixel_bytes]
      error('Alpha channel not supported: '+file) unless @color_space
      error('Unknown compression method: '+file) if f.read(1)[0]!=0
      error('Unknown filter method: '+file) if f.read(1)[0]!=0
      error('Interlacing not supported: '+file) if f.read(1)[0]!=0
      f.read(4)
      # @parms='<</Predictor 15 /Colors '+(@pixel_bytes==2 ? '3' : '1')+' /BitsPerComponent '+@bits.to_s+' /Columns '+@width].to_s+'>>'
      @parms={:Predictor=>15, :Colors=>(@pixel_bytes==2 ? 3 : 1), :BitsPerComponent=>@bits, :Columns=>@width}
      # Scan chunks looking for palette, transparency and image data
      @transparency=''
      @palette=''
      @data=''
      @filter=:FlateDecode
      begin
        n = freadint(f)
        type=f.read(4)
        if type=='PLTE'
          # Read palette
          @palette=f.read(n)
          f.read(4)
        elsif type=='tRNS'
          # Read @transparency info
          t=f.read(n)
          if @pixel_bytes==0
            @transparency=[t[1]]
          elsif @pixel_bytes==2
            @transparency=[t[1],t[3],t[5]]
          else
            pos=t.index(0)
            @transparency=[pos] unless pos.nil?
          end
          f.read(4)
        elsif type=='IDAT'
          # Read image data block
          @data << f.read(n)
          f.read(4)
        elsif type=='IEND'
          break
        else
          f.read(n+4)
        end
      end while n
      f.close
      error('Missing palette in '+file) if @color_space==:Indexed and @palette==''
      if @transparency.is_a?(Array)
        mask=''
        @transparency.length.times { |i| mask += (@transparency[i].to_s+' ')*2 }
        @mask = [mask]
      end
    end

    # Read a 4-byte integer from file
    def freadint(f)
      f.read(4).unpack('N')[0]
    end

    def freadshort(f)
      f.read(2).unpack('n')[0]
    end

    def freadbyte(f)
      f.read(1).unpack('C')[0]
    end
  end


  # Content stream permit to record all the operations
  class ContentStream
    NUMERIC_CLASSES = [Float, Integer, Fixnum]
    LINE_DASH_STYLES = {:dotted=>{:dash=>[1, 1], :phase=>0.5}, :dashed=>{:dash=>[3], :phase=>2}, :solid=>{:dash=>[], :phase=>0}}
    LINE_CAP_STYLES = {:butt=>0, :round=>1, :square=>2}
    LINE_JOIN_STYLES = {:miter=>0, :round=>1, :bevel=>2}

    def initialize(document)
      @document = document
      @code = ''
      @font_size = 12
    end

    def to_s
      @code.strip
    end

    def child
      c = self.dup
      c.clean_code
      c
    end

    def clean_code
      @code = ''
    end

    def set_fill_color(a=nil, b=nil, c=nil, d=nil)
      a ||= 0
      color = color(a, b, c, d)
      return if color == @fill_color
      @fill_color = color
      add @fill_color.join(' ').downcase
      self
    end

    def set_line_color(a=nil, b=nil, c=nil, d=nil)
      a ||= 0
      color = color(a, b, c, d)
      # return if color == @line_color
      @line_color = color
      add @line_color.join(' ')
      self
    end

    def set_line_cap(value=nil)
      value ||= :butt
      # return if value == @line_cap
      cap = LINE_CAP_STYLES[value]
      @document.error('Unknown cap value: '+value.inspect) if cap.nil?
      @line_cap = value
      add cap.to_s+' J'    
      self
    end

    def set_line_join(value=nil)
      value ||= :miter
      # return if value == @line_join
      join = LINE_JOIN_STYLES[value]
      @document.error('Unknown join value: '+value.inspect) if join.nil?
      @line_join = value
      add join.to_s+' j'    
      self
    end

    def set_line_width(value=nil)
      value ||= 0
      # return if value == @line_width
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @line_width = value
      add @line_width.to_s+' w'
      self
    end

    def set_line_dash(pattern=nil, phase=nil, width=nil)    
      pattern ||= []
      phase ||= 0
      width ||= @line_width
      @document.error('Unvalid type to set dash style: '+phase.inspect) unless NUMERIC_CLASSES.include? phase.class
      @document.error('Unvalid type to set dash style: '+width.inspect) unless NUMERIC_CLASSES.include? width.class
      if pattern.is_a? Symbol and LINE_DASH_STYLES.keys.include? pattern
        style = LINE_DASH_STYLES[pattern]
        pattern, phase = style[:dash], style[:phase]
      end
      @document.error('Unvalid type to set dash style: '+pattern.inspect) unless pattern.is_a? Array
      pattern = pattern.collect{|x| x*width}
      phase *= width
      # return if pattern == @dash_pattern and phase == @dash_phase
      @dash_pattern, @dash_phase = pattern, phase
      add '['+@dash_pattern.join(' ')+'] '+@dash_phase.to_s+' d'
      self
    end

    def set_line(line={})
      self.set_line_cap(line[:cap])
      self.set_line_join(line[:join])
      self.set_line_color(line[:color])
      self.set_line_width(line[:width])
      self.set_line_dash(line[:style])
      self
    end

    def set_miter_limit(value=2)
      # return if value == @miter_limit
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @miter_limit = value
      add @miter_limit.to_s+' M'
      self
    end

    def set_flatness(value=0)
      return if value == @flatness
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @document.error('Value must be a number between 0.0 and 100.0') if value<0 or value>100
      @flatness = value
      add @flatness.to_s+' i'
      self
    end

    def text_object
      @document.error('A text object needs block') unless block_given?    
      yield object=self.child
      add_environment('BT', 'ET', object)
      self
    end

    def begin_text_object
      add 'BT'
      self
    end

    def end_text_object
      add 'ET'
      self
    end

    def select_font(name, size=nil)
      # return if @font_name==name and @font_size==size
      @document.error('Unvalid font name: '+name.inspect+', available fonts are '+@document.fonts.collect{|f| f[:name]}.join(', ')) if @document.defined_font(name).nil?
      @font_name = name
      unless size.nil?
        @document.error('Unvalid type to set size: '+size.inspect) unless NUMERIC_CLASSES.include? size.class
        @font_size = size
      end
      add '/'+@font_name.to_s+' '+@font_size.to_s+' Tf'
      self
    end

    # Get width of a string in the current font
    def get_string_width(string)
      @document.error('A font must be selected to compute a string width. ('+@font_name.inspect+'/'+@font_size.inspect+')') if @font_name.nil? or @font_size.nil?
      cw = @document.defined_font(@font_name)[:char_widths]
      @document.error('Char widths must be an Array: '+cw.inspect+' '+@font_name.inspect+' '+@document.fonts.inspect) unless cw.is_a? Array
      width = 0
      s = @document.ic ? @document.ic.iconv(string) : string
      s.to_s.ascii.each_byte { |char| width += cw[char] }
      return width*@font_size/1000.0
    end

    def move_text_position(x=nil, y=nil, leading=false)
      if x.nil? or y.nil?
        add 'T*'
      else
        @document.error('Unvalid type to set x coordinate: '+x.inspect) unless NUMERIC_CLASSES.include? x.class
        @document.error('Unvalid type to set y coordinate: '+y.inspect) unless NUMERIC_CLASSES.include? y.class
        add x.to_s+' '+y.to_s+(leading ? ' TD' : ' Td')
      end
      self
    end

    def set_character_spacing(value=0)
      return if value == @character_spacing
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @character_spacing = value
      add @character_spacing+' Tc'
      self
    end

    def set_word_spacing(value=0)
      return if value == @word_spacing
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @word_spacing = value
      add @word_spacing+' Tw'
      self
    end

    def set_horizontal_text_scaling(value=100)
      return if value == @horizontal_text_scaling
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @horizontal_text_scaling = value
      add @horizontal_text_scaling+' Tz'
      self
    end

    def set_text_leading(value=0)
      return if value == @text_leading
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @text_leading = value
      add @text_leading+' TL'
      self
    end
    
    def set_text_rendering_mode(value=0)
      return if value == @text_rendering_mode
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @document.error('Value must be a number between 0 and 7') if value<0 or value>7
      @text_rendering_mode = value.round
      add @text_rendering_mode+' Tr'
      self
    end

    def set_text_rise(value=0)
      return if value == @text_rise
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      @text_rise = value
      add @text_rise+' Tr'
      self
    end
    
    def set_text_rotate(value, x, y)
      @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      rad = value * Math::PI / 180
      set_text_matrix(Math.cos(rad), Math.sin(rad), -Math.sin(rad), Math.cos(rad), x, y)
      self
    end
    
    def set_text_matrix(a, b, c, d, e, f)
      a, b, c, d, e, f = a[0], a[1], a[2], a[3], a[4], a[5] if a.is_a? Array
      values = [a, b, c, d, e, f]
      return if values == @text_matrix
      for value in values
        @document.error('Value must be numeric: '+value.inspect) unless NUMERIC_CLASSES.include? value.class
      end
      @text_matrix = values
      add @text_matrix.join(' ')+' Tm'
      self
    end
    
    def show_text(text, eol=false, word_spacing=nil, character_spacing=nil)
      @document.error('A font must be selected before showing text') if @font_name.nil? or @font_size.nil?
      if eol
        if word_spacing.nil? or character_spacing.nil?
          add escape(text)+" '"
        else
          @word_spacing = word_spacing
          @character_spacing = character_spacing
          add @word_spacing.to_s+' '+@character_spacing.to_s+' '+escape(text)+' "'
        end
      else
        add escape(text)+' Tj'
      end
      self
    end

    def show_text_at(text, x, y, align=:left)
      w = get_string_width(text)
      nx = x
      if align==:center
        nx -= w.to_f/2
      elsif align==:right
        nx -= w.to_f
      end
      self.move_text_position(nx, y)
      self.show_text(text)
    end
    

    def new_graphics_state
      @document.error('A new graphics state needs block') unless block_given?
      yield object=self.child
      add_environment('q', 'Q', object)
      self
    end

    def save_graphics_state
      add 'q'
      self
    end

    def restore_graphics_state
      add 'Q'
      self
    end

    def concatenate_matrix(a, b, c, d, e, f)
      add a.to_s+' '+b.to_s+' '+c.to_s+' '+d.to_s+' '+e.to_s+' '+f.to_s+' cm'
      self
    end

    def invoke_xobject(name)
      add '/'+name.to_s+' Do'
      self
    end

    def move_to(x,y=nil)
      x, y = x[0], x[1] if x.is_a? Array
      @document.error('Unvalid type to set x coordinate: '+x.inspect) unless NUMERIC_CLASSES.include? x.class
      @document.error('Unvalid type to set y coordinate: '+y.inspect) unless NUMERIC_CLASSES.include? y.class
      add x.to_s+' '+y.to_s+' m'
      self
    end

    def line_to(x,y=nil)
      x, y = x[0], x[1] if x.is_a? Array
      @document.error('Unvalid type to set x coordinate: '+x.inspect) unless NUMERIC_CLASSES.include? x.class
      @document.error('Unvalid type to set y coordinate: '+y.inspect) unless NUMERIC_CLASSES.include? y.class
      add x.to_s+' '+y.to_s+' l'
      self
    end

    def curve_to(x1, y1, x2, y2=nil, x3=nil, y3=nil)
      if x2.is_a? Array
        x3, y3 = x2[0], x2[1] 
        x1 ||= []
        y1 ||= []
        @document.error('Unvalid type to set x1 coordinate: '+x1.inspect) unless x1.is_a? Array
        @document.error('Unvalid type to set y1 coordinate: '+y1.inspect) unless y1.is_a? Array
        x1, y1, x2, y2 = x1[0], x1[1], y1[0], y1[1]
      end
      @document.error('Unvalid type to set x1 coordinate: '+x1.inspect) unless NUMERIC_CLASSES.include? x1.class or x1.nil?
      @document.error('Unvalid type to set y1 coordinate: '+y1.inspect) unless NUMERIC_CLASSES.include? y1.class or x1.nil?
      @document.error('Unvalid type to set x2 coordinate: '+x2.inspect) unless NUMERIC_CLASSES.include? x2.class or x2.nil?
      @document.error('Unvalid type to set y2 coordinate: '+y2.inspect) unless NUMERIC_CLASSES.include? y2.class or x2.nil?
      @document.error('Unvalid type to set x3 coordinate: '+x3.inspect) unless NUMERIC_CLASSES.include? x3.class
      @document.error('Unvalid type to set y3 coordinate: '+y3.inspect) unless NUMERIC_CLASSES.include? y3.class
      @document.error('Unvalid curve: P1 or P2 needed') if x1.nil? and x2.nil?
      if x1.nil?
        add x2.to_s+' '+y2.to_s+' '+x3.to_s+' '+y3.to_s+' v'
      elsif x2.nil?
        add x1.to_s+' '+y1.to_s+' '+x3.to_s+' '+y3.to_s+' y'
      else
        add x1.to_s+' '+y1.to_s+' '+x2.to_s+' '+y2.to_s+' '+x3.to_s+' '+y3.to_s+' c'
      end
      self
    end

    def fill(rule=:nonzero_winding_number)
      add 'f'+(rule == :nonzero_winding_number ? '' : '*')
      self
    end

    def stroke(close=true)
      add (close ? 's' : 'S')
      self
    end

    def fill_and_stroke(close=true, rule=:nonzero_winding_number)
      add (close ? 'b' : 'B')+(rule == :nonzero_winding_number ? '' : '*')
      self
    end

    def paint(fill=true, stroke=true, close=true, rule=:nonzero_winding_number)
      if fill and stroke
        fill_and_stroke(close, rule)
      elsif fill
        fill(rule)
      elsif stroke
        stroke(close)
      end
    end

    def close_path
      add 'h'
      self
    end

    def end_path
      add 'n'
      self
    end

    def append_rectangle(x, y, width, height)
      @document.error('Unvalid type to set x coordinate: '+x.inspect) unless NUMERIC_CLASSES.include? x.class
      @document.error('Unvalid type to set y coordinate: '+y.inspect) unless NUMERIC_CLASSES.include? y.class
      @document.error('Unvalid type to set width coordinate: '+width.inspect) unless NUMERIC_CLASSES.include? width.class
      @document.error('Unvalid type to set height coordinate: '+height.inspect) unless NUMERIC_CLASSES.include? height.class    
      add x.to_s+' '+y.to_s+' '+width.to_s+' '+height.to_s+' re'
      self
    end

    private

    def add(operation)
      if @document.compress
        @code += ' '+operation
      else
        @code += operation+"\n"
      end
    end

    def add_environment(opening, closing, operations)
      if @document.compress
        add opening+' '+operations.to_s+' '+closing
      else
        add opening
        add operations.to_s.gsub(/^/, '  ')
        add closing
      end
    end

    def color(a, b=nil, c=nil, d=nil)
      a, b, c, d = a[0], a[1], a[2], a[3] if a.is_a? Array
      if a.is_a? String
        color = string_to_color(a) 
        a, b, c, d = color[0], color[1], color[2], color[3]
      end
      @document.error('Color channel A must be a number: '+a.inspect+' '+a.class.to_s) unless NUMERIC_CLASSES.include? a.class
      @document.error('Color channel A must be a number between 0.0 and 1.0') if a<0 or a>1
      if b.nil? or c.nil?
        [a.to_f, 'G']
      else
        @document.error('Color channel B must be a number: '+b.inspect+' '+b.class.to_s) unless NUMERIC_CLASSES.include? b.class
        @document.error('Color channel B must be a number between 0.0 and 1.0') if b<0 or b>1
        @document.error('Color channel C must be a number: '+c.inspect+' '+c.class.to_s) unless NUMERIC_CLASSES.include? c.class
        @document.error('Color channel C must be a number between 0.0 and 1.0') if c<0 or c>1
        if d.nil?
          [a.to_f, b.to_f, c.to_f, 'RG']
        else
          @document.error('Color channel D must be a number: '+d.inspect+' '+d.class.to_s) unless NUMERIC_CLASSES.include? d.class
          @document.error('Color channel D must be a number between 0.0 and 1.0') if d<0 or d>1
          [a.to_f, b.to_f, c.to_f, d.to_f, 'K']
        end
      end
    end

    def string_to_color(value)
      value = "#"+value[1..1]*2+value[2..2]*2+value[3..3]*2 if value=~/^\#[a-f0-9]{3}$/i
      array = if value=~/^\#[a-f0-9]{6}$/i
                [value[1..2].to_i(16), value[3..4].to_i(16), value[5..6].to_i(16)]
              elsif value=~/rgb\(\d+\,\d+\,\d+\)/i
                array = value.split /(\(|\,|\))/
                [array[2].strip, array[4].strip, array[6].strip].collect{|x| x[/\d*\.\d*/].to_f }
              elsif value=~/rgb\(\d+\%\,\d+\%\,\d+\%\)/i
                array = value.split /(\(|\,|\))/
                [array[2].strip, array[4].strip, array[6].strip].collect{|x| x[/\d*\.\d*/].to_f*2.55 }
              else
                [0, 0, 0]
              end
      array.collect{|x| x.to_f/255}
    end

    # Format a text string
    def escape(string)
      @document.escape(string)
    end

  end
end
