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
      doc.page(:size=>"A4") do |page|
        page.slice(:height=>70) do |s|
          s.text("Hello world")
        end
        page.slice do |s|
          s.text("Hello world")
        end
      end
      doc.page(:size=>"A5", :orientation=>:landscape, :margins=>40) do |page|
        page.slice do |s|
          s.text("ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει." * 15, :font=>"DejaVuSans", :align=>:center)
        end
      end
    end
  end
  

  def test_compiler
    for file in Dir.glob(Rails.root.join("config", "locales", "*", "prints", "sale*invoice*.xml"))
      File.open(file, "rb") do |f|
        code = Templating.compile(f.read, :xil)
      end
    end
  end


end
