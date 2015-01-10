# encoding: utf-8
require 'test_helper'

class TemplatingTest < Test::Unit::TestCase

  def test_hello_world
    Templating::Writer.generate_file("tmp/hello_world.pdf", :debug=>true, :title=>"Hello World!", :author=>"Brice Texier") do |doc|
      doc.font_family("LiberationSans", Templating.fonts_dir.join("LiberationSans-Regular.ttf").to_s,
               Templating.fonts_dir.join("LiberationSans-Bold.ttf").to_s,
               Templating.fonts_dir.join("LiberationSans-Italic.ttf").to_s,
               Templating.fonts_dir.join("LiberationSans-BoldItalic.ttf").to_s)
      doc.font_family("DejaVuSans", Templating.fonts_dir.join("DejaVuSans.ttf").to_s,
               Templating.fonts_dir.join("DejaVuSans-Bold.ttf").to_s,
               Templating.fonts_dir.join("DejaVuSans-Oblique.ttf").to_s,
               Templating.fonts_dir.join("DejaVuSans-BoldOblique.ttf").to_s)
      doc.page(:size=>"A4", :margins=>[41.89, 45.28, 40, 40]) do |page|
        page.slice(:height=>200, :margins=>[15.0, 32.0]) do |s|
          s.text("Hello world! [gjpq]", :align=>:center, :margins=>10, :size=>16, :bold=>true, :fill=>'#0077', :radius=>10)
          s.box(:left=>200, :top=>20) do
            s.box(:left=>40, :top=>40, :height=>50, :width=>100) do
              s.text("Boxed!")
              s.box(:left=>8, :top=>32, :height=>25, :width=>72) do
                #s.text("Re-boxed!")                
              end
              s.box(:left=>-50, :top=>72, :width=>137) do
                #s.text("Re-boxed!")                
              end
            end
          end
        end
        page.slice(:margins=>27) do |s|
          s.text("Hello world! [gjpq] " * 17, :align=>:center, :color=>'#D40', :font=>'Times-Roman', :size=>12, :fill=>'#0377',:margins=>4)
        end
        page.slice do |s|
          s.box(:left=>20, :top=>20, :width=>100) do
            s.text("Hello world! " * 10)
          end
          s.image(File.join(File.dirname(__FILE__), "images", "butterfly.jpg"), :left=>140, :width=>300, :top=>5)
          s.rectangle(:height=>100, :width=>60, :fill=>"#FE9", :radius=>5, :left=>445, :top=>5)
        end
        page.slice(:bottom=>true) do |s|
          s.ellipse(100, :left=>s.current_box.width/2, :top=>80, :radius_y=>50, :fill=>'#ABC')
          bh = 7
          s.rectangle(:height=>bh, :fill=>"#AAA")
          s.rectangle(:height=>bh, :fill=>"#BBB", :top=>1*bh)
          s.rectangle(:height=>bh, :fill=>"#CCC", :top=>2*bh)
          s.rectangle(:height=>bh, :fill=>"#DDD", :top=>3*bh)
          s.rectangle(:height=>bh, :fill=>"#EEE", :top=>4*bh)
          
          s.box(:left=>300, :top=>20) do
            s.rectangle(:height=>50, :width=>50, :stroke=>"5pt dotted #F00")
            s.rectangle(:height=>50, :width=>50, :stroke=>"5pt dashed #0F0", :left=>70)
            s.rectangle(:height=>50, :width=>50, :stroke=>"5pt solid  #00F", :left=>140)
          end
          
          points = []
          gs = 70.0
          wl = 5
          xk = gs / wl.to_f
          power = 3
          for x in -wl..wl
            points << [(x+wl)*xk, gs*(1.to_f-(x**power).to_f/(wl**power).to_f)]
          end
          s.line(*(points + [{:stroke=>"1pt solid #007"}]))

          points = []
          12.times do 
            points << [rand(70), rand(70)]
          end
          s.polygon(*(points + [{:stroke=>"1pt dotted #700", :top=>50, :left=>200}]))
          s.polygon(*(points + [{:stroke=>"1pt solid #070",  :top=>50, :left=>270, :radius=>7}]))

          s.text("Footer", :align=>:center)
        end
      end
      doc.page(:size=>"A5", :orientation=>:landscape, :margins=>40.mm) do |page|
        page.slice() do |s|
          s.text("ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει. " * 15, :font=>"DejaVuSans", :align=>:center)
        end
      end
    end
  end


  # Test all templates
  code = ''
  for file in Dir.glob(Rails.root.join("config", "locales", "*", "prints", "*.xml"))
    File.open(file, "rb") do |f|
      code << "def test_template_#{file.gsub(/\W+/, '_')}\n"
      code << "  assert_nothing_raised(\"Template #{file} seems to be invalid\") do\n"
      code << "    Templating.compile(#{f.read.inspect}, :xil)\n"
      code << "  end\n"
      code << "end\n\n"
    end
  end
  eval(code)


end
