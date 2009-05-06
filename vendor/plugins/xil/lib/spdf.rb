require 'bigdecimal'
require 'zlib'

class Spdf
  VERSION = '0.1'
  PDF_VERSION = "1.3"
  LAYOUTS = { :single=>'/SinglePage', :continuous=>'/OneColumn', :two_left=>'/TwoColumnLeft', :two_right=>'/TwoColumnRight' }
  ZOOMS = { :page=>"/Fit", :width=>"/FitH null", :height=>"/FitV null" }
  LINE_DASH_STYLES = {:dotted=>{:dash=>[1, 1], :phase=>0.5}, :dashed=>{:dash=>[3], :phase=>2} }
  LINE_CAP_STYLES = {:butt=>0, :round=>1, :square=>2}
  LINE_JOIN_STYLES = {:miter=>0, :round=>1, :bevel=>2}
  JPEG_COLOR_SPACES = [nil, nil, nil, 'DeviceRGB', 'DeviceCMYK']
  PNG_COLOR_SPACES = ['DeviceGray', nil, 'DeviceRGB', 'Indexed']

  attr_accessor :title, :keywords, :creator, :author, :subject, :zoom, :layout
  attr_reader :fonts, :available_fonts

  def initialize
    @pages = []
    @page = -1
    @aliases = {}
    @fonts = {}
    @images = {}
    @producer = self.class.to_s+' '+VERSION
    
    @available_fonts={
      'courier'               => {:type=>:core, :base=>'Courier', :encoding=>'/WinAnsiEncoding', :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
      'courier-bold'          => {:type=>:core, :base=>'Courier-Bold', :encoding=>'/WinAnsiEncoding', :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
      'courier-italic'        => {:type=>:core, :base=>'Courier-Oblique', :encoding=>'/WinAnsiEncoding', :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
      'courier-bold-italic'   => {:type=>:core, :base=>'Courier-BoldOblique', :encoding=>'/WinAnsiEncoding', :char_widths=>[600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600, 600]},
      'helvetica'             => {:type=>:core, :base=>'Helvetica', :encoding=>'/WinAnsiEncoding', :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500]},
      'helvetica-bold'        => {:type=>:core, :base=>'Helvetica-Bold', :encoding=>'/WinAnsiEncoding', :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556]},
      'helvetica-italic'      => {:type=>:core, :base=>'Helvetica-Oblique', :encoding=>'/WinAnsiEncoding', :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, 350, 556, 350, 222, 556, 333, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 222, 222, 333, 333, 350, 556, 1000, 333, 1000, 500, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 260, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 556, 537, 278, 333, 333, 365, 556, 834, 834, 834, 611, 667, 667, 667, 667, 667, 667, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 500, 556, 556, 556, 556, 278, 278, 278, 278, 556, 556, 556, 556, 556, 556, 556, 584, 611, 556, 556, 556, 556, 500, 556, 500]},
      'helvetica-bold-italic' => {:type=>:core, :base=>'Helvetica-BoldOblique', :encoding=>'/WinAnsiEncoding', :char_widths=>[278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584, 350, 556, 350, 278, 556, 500, 1000, 556, 556, 333, 1000, 667, 333, 1000, 350, 611, 350, 350, 278, 278, 500, 500, 350, 556, 1000, 333, 1000, 556, 333, 944, 350, 500, 667, 278, 333, 556, 556, 556, 556, 280, 556, 333, 737, 370, 556, 584, 333, 737, 333, 400, 584, 333, 333, 333, 611, 556, 278, 333, 333, 365, 556, 834, 834, 834, 611, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 278, 278, 278, 278, 722, 722, 778, 778, 778, 778, 778, 584, 778, 722, 722, 722, 722, 667, 667, 611, 556, 556, 556, 556, 556, 556, 889, 556, 556, 556, 556, 556, 278, 278, 278, 278, 611, 611, 611, 611, 611, 611, 611, 584, 611, 611, 611, 611, 611, 556, 611, 556]},
      'times'                 => {:type=>:core, :base=>'Times-Roman', :encoding=>'/WinAnsiEncoding', :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 408, 500, 500, 833, 778, 180, 333, 333, 500, 564, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 564, 564, 564, 444, 921, 722, 667, 667, 722, 611, 556, 722, 722, 333, 389, 722, 611, 889, 722, 722, 556, 722, 667, 556, 611, 722, 722, 944, 722, 722, 611, 333, 278, 333, 469, 500, 333, 444, 500, 444, 500, 444, 333, 500, 500, 278, 278, 500, 278, 778, 500, 500, 500, 500, 333, 389, 278, 500, 500, 722, 500, 500, 444, 480, 200, 480, 541, 350, 500, 350, 333, 500, 444, 1000, 500, 500, 333, 1000, 556, 333, 889, 350, 611, 350, 350, 333, 333, 444, 444, 350, 500, 1000, 333, 980, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 200, 500, 333, 760, 276, 500, 564, 333, 760, 333, 400, 564, 300, 300, 333, 500, 453, 250, 333, 300, 310, 500, 750, 750, 750, 444, 722, 722, 722, 722, 722, 722, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 722, 722, 722, 722, 722, 722, 564, 722, 722, 722, 722, 722, 722, 556, 500, 444, 444, 444, 444, 444, 444, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 564, 500, 500, 500, 500, 500, 500, 500, 500]},
      'times-bold'            => {:type=>:core, :base=>'Times-Bold', :encoding=>'/WinAnsiEncoding', :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 555, 500, 500, 1000, 833, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 930, 722, 667, 722, 722, 667, 611, 778, 778, 389, 500, 778, 667, 944, 722, 778, 611, 778, 722, 556, 667, 722, 722, 1000, 722, 722, 667, 333, 278, 333, 581, 500, 333, 500, 556, 444, 556, 444, 333, 500, 556, 278, 333, 556, 278, 833, 556, 500, 556, 556, 444, 389, 333, 556, 500, 722, 500, 500, 444, 394, 220, 394, 520, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 1000, 350, 667, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 444, 722, 250, 333, 500, 500, 500, 500, 220, 500, 333, 747, 300, 500, 570, 333, 747, 333, 400, 570, 300, 300, 333, 556, 540, 250, 333, 300, 330, 500, 750, 750, 750, 500, 722, 722, 722, 722, 722, 722, 1000, 722, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 778, 778, 778, 778, 778, 570, 778, 722, 722, 722, 722, 722, 611, 556, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 500, 556, 500]},
      'times-italic'          => {:type=>:core, :base=>'Times-Italic', :encoding=>'/WinAnsiEncoding', :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 420, 500, 500, 833, 778, 214, 333, 333, 500, 675, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 675, 675, 675, 500, 920, 611, 611, 667, 722, 611, 611, 722, 722, 333, 444, 667, 556, 833, 667, 722, 611, 722, 611, 500, 556, 722, 611, 833, 611, 556, 556, 389, 278, 389, 422, 500, 333, 500, 500, 444, 500, 444, 278, 500, 500, 278, 278, 444, 278, 722, 500, 500, 500, 500, 389, 389, 278, 500, 444, 667, 444, 444, 389, 400, 275, 400, 541, 350, 500, 350, 333, 500, 556, 889, 500, 500, 333, 1000, 500, 333, 944, 350, 556, 350, 350, 333, 333, 556, 556, 350, 500, 889, 333, 980, 389, 333, 667, 350, 389, 556, 250, 389, 500, 500, 500, 500, 275, 500, 333, 760, 276, 500, 675, 333, 760, 333, 400, 675, 300, 300, 333, 500, 523, 250, 333, 300, 310, 500, 750, 750, 750, 500, 611, 611, 611, 611, 611, 611, 889, 667, 611, 611, 611, 611, 333, 333, 333, 333, 722, 667, 722, 722, 722, 722, 722, 675, 722, 722, 722, 722, 722, 556, 611, 500, 500, 500, 500, 500, 500, 500, 667, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 500, 500, 500, 500, 500, 500, 675, 500, 500, 500, 500, 500, 444, 500, 444]},
      'times-bold-italic'     => {:type=>:core, :base=>'Times-BoldItalic', :encoding=>'/WinAnsiEncoding', :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 389, 555, 500, 500, 833, 778, 278, 333, 333, 500, 570, 250, 333, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 333, 333, 570, 570, 570, 500, 832, 667, 667, 667, 722, 667, 667, 722, 778, 389, 500, 667, 611, 889, 722, 722, 611, 722, 667, 556, 611, 722, 667, 889, 667, 611, 611, 333, 278, 333, 570, 500, 333, 500, 500, 444, 500, 444, 333, 500, 556, 278, 278, 500, 278, 778, 556, 500, 500, 500, 389, 389, 278, 556, 444, 667, 500, 444, 389, 348, 220, 348, 570, 350, 500, 350, 333, 500, 500, 1000, 500, 500, 333, 1000, 556, 333, 944, 350, 611, 350, 350, 333, 333, 500, 500, 350, 500, 1000, 333, 1000, 389, 333, 722, 350, 389, 611, 250, 389, 500, 500, 500, 500, 220, 500, 333, 747, 266, 500, 606, 333, 747, 333, 400, 570, 300, 300, 333, 576, 500, 250, 333, 300, 300, 500, 750, 750, 750, 500, 667, 667, 667, 667, 667, 667, 944, 667, 667, 667, 667, 667, 389, 389, 389, 389, 722, 722, 722, 722, 722, 722, 722, 570, 722, 722, 722, 722, 722, 611, 611, 500, 500, 500, 500, 500, 500, 500, 722, 444, 444, 444, 444, 444, 278, 278, 278, 278, 500, 556, 500, 500, 500, 500, 500, 570, 500, 556, 556, 556, 556, 444, 500, 444]},
      'symbol'                => {:type=>:core, :base=>'Symbol', :char_widths=>[250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 333, 713, 500, 549, 833, 778, 439, 333, 333, 500, 549, 250, 549, 250, 278, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 278, 278, 549, 549, 549, 444, 549, 722, 667, 722, 612, 611, 763, 603, 722, 333, 631, 722, 686, 889, 722, 722, 768, 741, 556, 592, 611, 690, 439, 768, 645, 795, 611, 333, 863, 333, 658, 500, 500, 631, 549, 549, 494, 439, 521, 411, 603, 329, 603, 549, 549, 576, 521, 549, 549, 521, 549, 603, 439, 576, 713, 686, 493, 686, 494, 480, 200, 480, 549, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 750, 620, 247, 549, 167, 713, 500, 753, 753, 753, 753, 1042, 987, 603, 987, 603, 400, 549, 411, 549, 549, 713, 494, 460, 549, 549, 549, 549, 1000, 603, 1000, 658, 823, 686, 795, 987, 768, 768, 823, 768, 768, 713, 713, 713, 713, 713, 713, 713, 768, 713, 790, 790, 890, 823, 549, 250, 713, 603, 603, 1042, 987, 603, 987, 603, 494, 329, 790, 790, 786, 713, 384, 384, 384, 384, 384, 384, 494, 494, 494, 494, 0, 329, 274, 686, 686, 686, 384, 384, 384, 384, 384, 384, 494, 494, 494, 0]},
      'zapfdingbats'          => {:type=>:core, :base=>'ZapfDingbats', :char_widths=>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 278, 974, 961, 974, 980, 719, 789, 790, 791, 690, 960, 939, 549, 855, 911, 933, 911, 945, 974, 755, 846, 762, 761, 571, 677, 763, 760, 759, 754, 494, 552, 537, 577, 692, 786, 788, 788, 790, 793, 794, 816, 823, 789, 841, 823, 833, 816, 831, 923, 744, 723, 749, 790, 792, 695, 776, 768, 792, 759, 707, 708, 682, 701, 826, 815, 789, 789, 707, 687, 696, 689, 786, 787, 713, 791, 785, 791, 873, 761, 762, 762, 759, 759, 892, 892, 788, 784, 438, 138, 277, 415, 392, 392, 668, 668, 0, 390, 390, 317, 317, 276, 276, 509, 509, 410, 410, 234, 234, 334, 334, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 732, 544, 544, 910, 667, 760, 760, 776, 595, 694, 626, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 788, 894, 838, 1016, 458, 748, 924, 748, 918, 927, 928, 928, 834, 873, 828, 924, 924, 917, 930, 931, 463, 883, 836, 836, 867, 867, 696, 696, 874, 0, 874, 760, 946, 771, 865, 771, 888, 967, 888, 831, 873, 927, 970, 918, 0]}
    }
  end

  def new_page(format=[], rotate=0)
    error('Parameter format must be an array') unless format.is_a? Array
    format[0] ||= 1000.0
    error('Parameter format can only contains numeric values') unless [Integer, Float, BigDecimal].include? format[0].class
    format[1] ||= format[0]*1.414
    @pages ||= []
    @page = @pages.size
    rotate = 90*(rotate.to_f/90).round
    @pages << {:format=>format, :items=>[], :rotate=>rotate}
  end

  def alias(key, value)
    @aliases[key] = value
  end

  def image(file, x, y, params={}, page=nil)
    self.new_page if @page<0
    if @images[file].nil?
      error("File does not exists (#{file.inspect})") unless File.exists? file
      @images[file] = image_info(file)
    end
    params[:x] = x
    params[:y] = y
    params[:image] = file
    @pages[page||@page][:items] << {:nature=>:image, :params=>params}
  end

  def line(points, params={}, page=nil)
    self.new_page if @page<0
    error("Unvalid list of point") unless points.is_a? Array
    points.each{|p| error("Unvalid point: #{p.inspect}") unless is_a_point? p}
    params[:points] = points
    @pages[page||@page][:items] << {:nature=>:line, :params=>params}
  end

  def box(params={}, page=nil)
    self.new_page if @page<0
    params[:font] ||= {}
    params[:font][:family] ||= 'Times'
    params[:font][:bold] ||= false
    params[:font][:italic] ||= false
    get_font(params[:font][:family], params[:font][:bold], params[:font][:italic])
    @pages[page||@page][:items] << {:nature=>:box, :params=>params}
  end

  def text(content, x, y, params={}, page=nil)
    params[:text] = content
    params[:x] = x
    params[:y] = y
    box(params, page)
  end

  def generate(options={})
    yield self if block_given?
    @compress = false
    pdf_data = build
    if options[:file]
      open('/tmp/test.pdf','wb') do |f|
        f.write(pdf_data)
      end
    else
      return pdf_data
    end
  end

  private

  def error(message, nature=nil)
    raise Exception.new("#{self.class.to_s} error: #{message}")
  end

  def build
    @objects = [0]
    @objects_count = 0
    @now = Time.now
    # Resources
    resources_object = build_resources
    # Pages
    pages_object, first_page_object = build_pages(resources_object)
    # build_resources
    # Info
    info_object = build_info
    # Catalog
    root_object = build_catalog(pages_object, first_page_object)

    # Building of the complete document
    pdf = "%PDF-#{PDF_VERSION}\n\n"
    xref  = "xref\n"
    xref += "0 #{(@objects_count+1).to_s}\n"
    xref += "0000000000 65535 f \n"
    for i in 1..@objects_count
      xref += sprintf('%010d 00000 n ', pdf.length)+"\n"
      pdf += i.to_s+" 0 obj\n"
      pdf += @objects[i]
      pdf += "endobj\n\n"      
    end
    length = pdf.length
    pdf += xref
    pdf += "trailer\n"
    trailer = [['Size', (@objects_count+1).to_s], ['Root', root_object.to_s+' 0 R']]
    trailer << ['Info', info_object.to_s+' 0 R'] unless info_object.nil?
    pdf += dictionary(trailer)+"\n"
    pdf += "startxref\n"
    pdf += length.to_s+"\n"
    pdf += "%%EOF\n"
    pdf
  end

  def build_info
    info = []
    info << ['Producer', textstring(@producer)] unless @producer.nil?
    info << ['Title', textstring(@title)] unless @title.nil?
    info << ['Subject', textstring(@subject)] unless @subject.nil?
    info << ['Author', textstring(@author)] unless @author.nil?
    info << ['Keywords', textstring(@keywords)] unless @keywords.nil?
    info << ['Creator', textstring(@creator)] unless @creator.nil?
    info << ['CreationDate', textstring('D:'+@now.strftime("%Y%m%d%H%M%S%z"))]
    info << ['ModDate', textstring('D:'+@now.strftime("%Y%m%d%H%M%S%z"))]
    new_object(info)
  end

  def build_catalog(pages_object, first_page=nil)
    catalog = [['Type', '/Catalog'],
               ['Pages', "#{pages_object.to_s} 0 R"]]
    if first_page and not zoom.nil?
      zoom = if ZOOMS.keys.include? @zoom
               ZOOMS[@zoom]
             elsif [Float, Integer].include? @zoom.class
               "/XYZ null null #{(@zoom/100).to_s}"
             else
               ZOOMS[:page]
             end
      catalog << ['OpenAction', "[#{first_page} 0 R #{zoom}]"]
    end
    catalog << ['PageLayout', LAYOUTS[@layout]||LAYOUTS[:coutinuous]] unless @layout.nil?
    new_object(catalog)
  end

  # Build the pages, page, content objects
  def build_pages(resources_object, parent_object=nil)
    pages_count = @pages.size
    pages = []
    pages_object = new_object    
    for page in @pages
      # Page content
      contents_object = new_stream_object(build_page(page))
      # Page
      dict = [['Type', '/Page'], ['Parent', "#{pages_object} 0 R"], # Required
              ['MediaBox', sprintf('[0 0 %.2f %.2f]', page[:format][0], page[:format][1])], # Required
              ['Resources', resources_object.to_s+' 0 R'], # Required
              ['Contents', contents_object.to_s+' 0 R']]
      dict << ['Rotate', page[:rotate]] if page[:rotate] != 0
      pages << new_object(dict)
    end
    # Pages root
    dict = [['Type', '/Pages'], ['Kids', '['+pages.collect{|i| i.to_s+' 0 R'}.join(' ')+']'], ['Count',pages.size.to_s]]
    dict << ['Parent', parent_object+' 0 R'] unless parent_object.nil?
    pages_root = new_object(dict, pages_object)
    return pages_root, pages[0]
  end


  def build_page(page)
    code = ''
    page_width  = page[:format][0]
    page_height = page[:format][1]
    for item in page[:items]
      nature = item[:nature]
      params = item[:params]
      if nature==:box
        text = params[:text]
        if text
          font = get_font(params[:font][:family], params[:font][:bold], params[:font][:italic])
          size = params[:font][:size]||12
          x = params[:x]||0
          y = page_height-0.7*size-(params[:y]||0)
          code += "BT /#{font[:name]} #{size} Tf #{x} #{y} Td #{textstring(text)} Tj ET\n"
        end
      elsif nature==:image
        image = @images[item[:params][:image]]
        h = params[:height]
        w = params[:width]
        if w and h.nil?
          h = w*image[:height]/image[:width]
        elsif w.nil? and h
          w = h*image[:width]/image[:height]
        elsif w.nil? and h.nil?
          h = image[:height].to_f/4
          w = image[:width].to_f/4
        end
        x = (params[:x]||0)
        y = page_height-(params[:y]||0)-h
        code += sprintf('q %.2f 0 0 %.2f %.2f %.2f cm /'+image[:name]+" Do Q\n", w, h, x, y)
      elsif nature==:line
        border = params[:border]
        width = border[:width]||2
        points = params[:points]
        style = border[:style]
        code += "#{LINE_CAP_STYLES[border[:cap]||:round]} J #{LINE_JOIN_STYLES[border[:join]||:round]} j " # Set Line Cap (0, 1 ou 2)
        code += self.class.string_to_color(border[:color]).collect{|x| x.to_f/255}.join(' ')+' RG ' if border[:color]
        code += width.to_s+' w '
        style = LINE_DASH_STYLES[style] if LINE_DASH_STYLES.keys.include? style
        code += "[#{(style[:dash]||[]).collect{|x| x*width}.join(' ')}] #{(style[:phase]||0)*width} d " if style.is_a? Hash
        points.size.times do |i|
          code += points[i][0].to_s+' '+(page_height-points[i][1]).to_s+' '+(i==0 ? 'm' : 'l')+' '
        end
        code += " S\n"
      end
    end

    return code
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


  def build_resources
    resources_object = new_object
    # Build fonts objects
    fonts = []
    for key, font in @fonts
      dict = [['Type', '/Font'],
              ['Name', '/'+font[:name]]]
      if font[:type] == :core
        dict << ['Subtype', '/Type1']
        dict << ['BaseFont', '/'+font[:base]]
        dict << ['Encoding', font[:encoding]] if font[:encoding]
      else
        error("Unsupported type of font: #{font[:type].inspect}")
      end
      fonts << [font[:name], new_object(dict).to_s+' 0 R']
    end

    # Build images objects
    images = []
    for key, image in @images
      object = new_object do |lines|
        dict = [['Type', '/XObject'], ['Subtype', '/Image'],
                ['Width', image[:width]], ['Height', image[:height]]]
        if image[:color_space]=='Indexed'
          dict << ['ColorSpace',  "[/Indexed /DeviceRGB #{image[:palette].length/3-1} #{resources_object} 0 R]"]
        else
          dict << ['ColorSpace', '/'+image[:color_space]]
          dict << ['Decode', '[1 0 1 0 1 0 1 0]'] if image[:color_space]=='DeviceCMYK'
        end
        dict << ['BitsPerComponent', image[:bits_per_component]]
        dict << ['DecodeParms', image[:parms]] if image[:parms]
        dict << ['Mask', image[:mask]] if image[:mask]
        dict << ['Filter', image[:filter]] if image[:filter]
        dict << ['Length', image[:data].length]
        lines << dictionary(dict)
        lines << new_stream(image[:data])
      end
      image[:name] = 'I'+images.size.to_s
      images << [image[:name], object.to_s+' 0 R']
    end

    # Resource object
    resources = [['ProcSet', '[/PDF /Text /ImageB /ImageC /ImageI]']]
    resources << ['Font', fonts]
    resources << ['XObject', images]
    new_object(resources, resources_object)
  end


  def new_object(data=nil, object_number=nil)
    if object_number.nil?
      @objects_count += 1
      object_number = @objects_count
      @objects[object_number] = ''
    end
    if block_given?
      lines = []
      yield(lines)
      @objects[object_number] += lines.join("\n")+"\n"
    elsif not data.nil?
      @objects[object_number] += (data.is_a?(Array) ? dictionary(data) : data)+"\n"
    end
    object_number
  end

  def new_stream_object(stream)
    filter = ''
    if @compress
      filter = '/Filter /FlateDecode '
      stream = Zlib::Deflate.deflate(stream)
    end
    new_object do |lines|
      lines << "\<\<"+filter+'/Length '+stream.length.to_s+"\>\>"
      lines << new_stream(stream)
    end
  end

  def new_stream(stream)
    "stream\n"+stream+"\nendstream"
  end

  def dictionary(dict=[], depth=0)
    raise Exception.new('Only Array type are accepted as dictionary type ('+dict.class.to_s+')') unless dict.is_a? Array
    eol = (dict.size>1 and not @compress)
    code  = "\<\<"
    code += "\n" if eol
    for key, value in dict
      code += "  "*depth+'/'+key.to_s+' '
      code += value.is_a?(Array) ? dictionary(value, depth+1) : value.to_s
      code += "\n" if eol
    end
    code += "  "*depth+"\>\>"
    code
  end

  def get_font(family_name='Times', bold=false, italic=false)
    label = family_name.downcase+(bold ? '-bold' : '')+(italic ? '-italic' : '')
    font = @fonts[label]
    if font.nil?
      font = @available_fonts[label]
      error("Unavailable font: #{label}") if font.nil?
      font[:name] = 'F'+(@fonts.size+1).to_s
      @fonts[label] = font
    end
    font
  end

  # Escape special characters
  def escape(string)
    string.gsub('\\','\\\\').gsub('(','\\(').gsub(')','\\)').gsub("\r",'\\r')
  end

  # Format a text string
  def textstring(string)
    '('+escape(string.to_s)+')'
  end
  
  def image_info(file)
    extensions = {'jpeg'=>'jpeg', 'jpg'=>'jpeg', 'png'=>'png'}    
    extension = file.split('.')[-1]
    error("Image type not supported: #{extension}, (Supported: #{extensions.keys.join(', ')})") unless extensions.keys.include? extension
    send("image_info_"+extensions[extension], file)
  end

  # jpeg marker codes
  M_SOF0  = 0xc0
  M_SOF1  = 0xc1
  M_SOF2  = 0xc2
  M_SOF3  = 0xc3
  
  M_SOF5  = 0xc5
  M_SOF6  = 0xc6
  M_SOF7  = 0xc7

  M_SOF9  = 0xc9
  M_SOF10 = 0xca
  M_SOF11 = 0xcb

  M_SOF13 = 0xcd
  M_SOF14 = 0xce
  M_SOF15 = 0xcf

  M_SOI   = 0xd8
  M_EOI   = 0xd9
  M_SOS   = 0xda

  def image_info_jpeg(file)
    result = nil
    File.open(file, "rb") do |f|
      marker = image_info_jpeg_next_marker(f)
      return nil if marker != M_SOI
      while result.nil?
        marker = image_info_jpeg_next_marker(f)
        # puts('Marker : '+marker.to_s(16))
        case marker
        when M_SOF0, M_SOF1, M_SOF2, M_SOF3, M_SOF5, M_SOF6, M_SOF7, M_SOF9, M_SOF10, M_SOF11, M_SOF13, M_SOF14, M_SOF15 then
          length = freadshort(f)
          if result.nil?
            result = {}
            result[:bits_per_component] = freadbyte(f)
            result[:height]   = freadshort(f)
            result[:width]    = freadshort(f)
            result[:channels] = freadbyte(f)
            f.seek(length - 8, IO::SEEK_CUR)
          else
            f.seek(length - 2, IO::SEEK_CUR)
          end
        when M_SOS, M_EOI then
          return nil
        else
          length = freadshort(f)
          f.seek(length - 2, IO::SEEK_CUR)
        end
      end
    end
    f = open(file, 'rb')
    data = f.read
    f.close
    result[:color_space] = JPEG_COLOR_SPACES[result[:channels]]||'DeviceGray' if result[:channels]
    result[:data] = data
    result[:filter] = '/DCTDecode'
    result[:bits_per_component] ||= 8
    result
  end

  def image_info_jpeg_next_marker(f)
    begin
      while (c = freadbyte(f)) != 0xff
      end
      c = freadbyte(f)
    end while c == 0 # look for 0xff
    return c
  end
  
  def image_info_png(file)
    f=open(file,'rb')
    error('Not a PNG file: '+file) unless f.read(8)==137.chr+'PNG'+13.chr+10.chr+26.chr+10.chr
    f.read(4)
    error('Incorrect PNG file: '+file) if f.read(4)!='IHDR'
    result = {}
    result[:width]  = freadint(f)
    result[:height] = freadint(f)
    result[:bits_per_component] = f.read(1)[0]
    error('16-bit depth not supported: '+file) if result[:bits_per_component]>8
    ct=f.read(1)[0]
    result[:color_space] = PNG_COLOR_SPACES[ct]
    error('Alpha channel not supported: '+file) unless result[:color_space]
    error('Unknown compression method: '+file) if f.read(1)[0]!=0
    error('Unknown filter method: '+file) if f.read(1)[0]!=0
    error('Interlacing not supported: '+file) if f.read(1)[0]!=0
    f.read(4)
    # result[:parms]='<</Predictor 15 /Colors '+(ct==2 ? '3' : '1')+' /BitsPerComponent '+result[:bits_per_component].to_s+' /Columns '+result[:width].to_s+'>>'
    result[:parms]=[['Predictor', 15], ['Colors', (ct==2 ? '3' : '1')],
                    ['BitsPerComponent', result[:bits_per_component]], ['Columns', result[:width]]]
    # Scan chunks looking for palette, transparency and image data
    transparency=''
    result[:palette]=''
    result[:data]=''
    result[:filter]='/FlateDecode'
    begin
      n = freadint(f)
      type=f.read(4)
      if type=='PLTE'
        # Read palette
        result[:palette]=f.read(n)
        f.read(4)
      elsif type=='tRNS'
        # Read transparency info
        t=f.read(n)
        if ct==0
          transparency=[t[1]]
        elsif ct==2
          transparency=[t[1],t[3],t[5]]
        else
          pos=t.index(0)
          transparency=[pos] unless pos.nil?
        end
        f.read(4)
      elsif type=='IDAT'
        # Read image data block
        result[:data] << f.read(n)
        f.read(4)
      elsif type=='IEND'
        break
      else
        f.read(n+4)
      end
    end while n
    f.close
    error('Missing palette in '+file) if result[:color_space]=='Indexed' and result[:palette]==''
    if transparency.is_a?(Array)
      mask=''
      transparency.length.times { |i| mask += (transparency[i].to_s+' ')*2 }
      result[:mask] = '['+mask+']'
    end
    result
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



if __FILE__==$0
  pdf = Spdf.new
  pdf.title = 'Enfin un moteur PDF lisible'
  pdf.new_page([595.28, 841.89])
  pdf.image('sample3.jpg', 300, 20, :width=>275)
  pdf.image('sample3.jpg', 300, 300, :height=>100)
  pdf.image('sample.jpg', 420, 300, :height=>100)
  pdf.image('sample4.png', 300, 600, :width=>275)
  pdf.line([[300,20], [420, 300], [400, 400], [350, 350]], :border=>{:width=>10, :style=>:dashed, :color=>'#12C', :join=>:miter})
  pdf.line([[30,20], [42, 300], [40, 400], [35, 350]], :border=>{:width=>1, :style=>:dashed, :color=>'#c12', :cap=>:butt})
  pdf.box(:text=>'Hello World!', :x=>20, :y=>20)
  fs = ['Courier', 'Times', 'Helvetica']
  h = 20
  for j in [50,20*(fs.size+1)*4+50]
    fs.size.times do |i|
      pdf.text('Hello World! Test pour Spdf', 50, i*4*h+j+0*h, :font=>{:family=>fs[i], :size=>12})
      pdf.text('Hello World! Test pour Spdf', 50, i*4*h+j+1*h, :font=>{:family=>fs[i], :size=>14, :bold=>true})
      pdf.text('Hello World! Test pour Spdf', 50, i*4*h+j+2*h, :font=>{:family=>fs[i], :size=>16, :italic=>true})
      pdf.text('Hello World! Test pour Spdf', 50, i*4*h+j+3*h, :font=>{:family=>fs[i], :size=>18, :bold=>true, :italic=>true})
    end
  end
  pdf.text('Hello World! Deuxième', 100, 630, :font=>{:family=>'Courier', :bold=>true, :size=>16})
  pdf.text('Hello World! Test pour Spdf', 100, 660, :font=>{:family=>'Symbol', :size=>16})
  pdf.new_page([1200.0,300.0], 90)
  pdf.image('sample2.jpg', 600, 20, :height=>260)
  pdf.text('Hello World! Encore une mission reussie pour Spdf', 200, 200, :font=>{:family=>'Courier', :size=>16})
  pdf.image('sample2.jpg', 300, 20)
  pdf.generate
end
