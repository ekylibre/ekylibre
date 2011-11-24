# encoding: UTF-8
require 'test_helper'

class TemplatingTest < Test::Unit::TestCase

  def test_hello_world
    Templating::Writer.generate_file("hello_world.pdf", :debug=>true) do |doc|
      doc.font_family("LiberationSans", Templating.fonts_dir.join("LiberationSans-Regular.ttf").to_s,
               Templating.fonts_dir.join("LiberationSans-Bold.ttf").to_s,
               Templating.fonts_dir.join("LiberationSans-Italic.ttf").to_s,
               Templating.fonts_dir.join("LiberationSans-BoldItalic.ttf").to_s)
      doc.font_family("DejaVuSans", Templating.fonts_dir.join("DejaVuSans.ttf").to_s,
               Templating.fonts_dir.join("DejaVuSans-Bold.ttf").to_s,
               Templating.fonts_dir.join("DejaVuSans-Oblique.ttf").to_s,
               Templating.fonts_dir.join("DejaVuSans-BoldOblique.ttf").to_s)
      doc.page(:size=>"A4", :margins=>[41.9, 55.3, 40, 40]) do |page|
        page.slice(:height=>200) do |s|
          s.text("Hello world")
          s.box(200, 20) do
            s.box(40, 40, :height=>50, :width=>100) do
              s.text("Boxed!")
              s.box(0, 40) do
                s.text("Re-boxed!")                
              end
            end
          end
        end
        page.slice(:resize=>true) do |s|
          s.image(File.join(File.dirname(__FILE__), "images", "butterfly.jpg"))
          s.text("Hello world! " * 20, :width=>100.mm, :left=>20.mm, :top=>10.mm)
        end
        page.slice(:height=>20, :bottom=>true) do |s|
          s.text("Footer", :align=>:center)
        end
      end
      doc.page(:size=>"A5", :orientation=>:landscape, :margins=>40.mm) do |page|
        page.slice(:resize=>true) do |s|
          s.text("ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει. " * 15, :font=>"DejaVuSans", :align=>:center)
        end
      end
    end
  end
  

  def test_compiler
    for file in Dir.glob(Rails.root.join("config", "locales", "*", "prints", "sale*invoice*.xml"))
      File.open(file, "rb") do |f|
        # code = Templating.compile(f.read, :xil)
      end
    end
  end


end
