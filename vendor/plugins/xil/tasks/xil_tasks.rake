namespace :xil do

  desc "Build a sample PDF with Ebi"
  task :ebi => :environment do
    pdf = Ebi::Document.new(:encoding=>'UTF-8')
    pdf.title = 'Enfin un moteur PDF lisible'

    pdf.new_page([595.28, 841.89])
    pdf.box(10, 10, 300, 50, "Test euro : €€€€€€€€€€€€€€€€€€€€€€€€€€€€ \\200", :border=>{:color=>'#aaa'}, :background=>'#DEF', :font=>{:color=>'#75A', :size=>12})
    
    for angle in 0..1
      pdf.new_page([595.28, 841.89], angle*90)
      full = true
      if full
        pdf.image("#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/chrome.jpg", 300, 20, :width=>275)
        pdf.image("#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/chrome.jpg", 300, 300, :height=>100)
        pdf.image("#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/seasons.jpg", 420, 300, :height=>100)
        pdf.image("#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/graph.png", 300, 600, :width=>275)
      end
      pdf.line([[300,20], [420, 300], [400, 400], [350, 350]], :border=>{:width=>10, :style=>:dashed, :color=>'#12C', :join=>:miter})
      pdf.line([[30,20], [42, 300], [40, 400], [35, 350]], :border=>{:width=>1, :style=>:dashed, :color=>'#c12', :cap=>:butt})
      pdf.line([[50,20], [92, 300], [90, 400], [85, 350]], :border=>{:width=>1, :style=>:dashed, :color=>'#183', :cap=>:butt})
      if full
        fs = ['Courier', 'Times', 'Helvetica']
        h = 20
        for j in [50,20*(fs.size+1)*4+50]
          fs.size.times do |i|
            pdf.box(50, i*4*h+j+0*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>12})
            pdf.box(50, i*4*h+j+1*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>14, :bold=>true})
            pdf.box(50, i*4*h+j+2*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>16, :italic=>true})
            pdf.box(50, i*4*h+j+3*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>18, :bold=>true, :italic=>true})
          end
        end
      end
      pdf.box(40, 40, 300, 60, "Heppo World! (Encadré)", :border=>{:color=>'#aaa'}, :background=>'#DEF', :font=>{:color=>'#75A', :size=>12})
      pdf.box(40, 40, 300, 60, "Heppo World! (Centré)", :border=>{:color=>'#aaa'}, :font=>{:color=>'#75A', :align=>'center middle', :size=>12})
      pdf.box(40, 40, 300, 60, "Heppo World! (Droite)", :border=>{:color=>'#aaa'}, :font=>{:color=>'#75A', :align=>'right bottom', :size=>12})
      pdf.box(40, 40, 150, 30, nil, :border=>{:color=>'#777'})


      #pdf.box(20,800, 400, 30, "ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει." * 20)
      
      pdf.box(40,     40+12, 80, 48, nil, :background=>'#777')
      pdf.box(40+110, 40,    80, 24, nil, :background=>'#778')
      pdf.box(40+110, 40+36, 80, 24, nil, :background=>'#779')
      pdf.box(40+220, 40,    80, 48, nil, :background=>'#77A')



      pdf.box(20,800, 400, 30, '\053'* 20)
    end

    pdf.new_page([560, 560])
    nb = 32
    hl = (560 - 60)/nb
    lc = (560 - 60)/8
    for i in 0..255
      pdf.box((i/nb)*lc+30, (i % nb)*hl+30, hl, 20, i.to_s(8).rjust(3,'0'))
      pdf.box((i/nb)*lc+55, (i % nb)*hl+30, hl, 20, '\\'+i.to_s(8).rjust(3,'0'), :font=>{:bold=>true})
    end

    for i in 0..399
      pdf.new_page([595.28, 841.89])
      pdf.box(30,  30, 300, 50, i.to_s, :font=>{:color=>'#75'+(i.to_f/25).to_i.to_s(16), :size=>360})
      pdf.box(30, 400, 300, 50, i.to_s, :font=>{:color=>'#7A'+(i.to_f/25).to_i.to_s(16), :size=>360})
    end
    pdf.generate :file=>'ebi.pdf'
  end









  desc "Build a sample PDF with Ebi"
  task :hebi => :environment do
    pdf = Hebi::Document.new(:encoding=>'UTF-8')
    pdf.title = 'Enfin un moteur PDF lisible'

    pdf.new_page([595.28, 841.89])
    pdf.set_fill_color(0.5, 0.6, 0.7)
    pdf.set_line_color(0.5, 0.6, 0.7)
    pdf.set_line_color
    pdf.image("#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/chrome.jpg", 300, 20, 275)
    pdf.font "Times", :size=>12
    pdf.text "Blabla bla blablb bla bla", :at=>[140, 140]

    string, width = "Blabla bla blablb bla bla. "*30, 200
    height = pdf.get_string_height(string, width, "Times", 12)
    pdf.text string+height.to_s, :at=>[304, 640], :width=>width
    pdf.text "Blabla solor bla ipsum ba bla bla. "*22+height.to_s, :at=>[300, 640], :width=>width, :align=>:right
    pdf.text "Lorem ipsum dolor sit amet. "*20+height.to_s, :at=>[302, 340], :width=>200, :align=>:center



    for angle in 0..1
      pdf.new_page([595.28, 841.89], angle*90)
      full = true
      pdf.image("#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/chrome.jpg", 300, 400, 275)
      pdf.image("#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/graph.png", 300,  000, 275)
      pdf.line([[300,20], [420, 300], [400, 400], [350, 350]], :border=>{:width=>10, :style=>:dashed, :color=>'#12C', :join=>:miter})
      pdf.line([[30,20], [42, 300], [40, 400], [35, 350]], :border=>{:width=>1, :style=>:dashed, :color=>'#c12', :cap=>:butt})
      pdf.line([[50,20], [92, 300], [90, 400], [85, 350]], :border=>{:width=>1, :style=>:dashed, :color=>'#183', :cap=>:butt})
      if full
        fs = ['Courier', 'Times', 'Helvetica']
        h = 20
        for j in [50,20*(fs.size+1)*4+50]
          fs.size.times do |i|
            pdf.box(50, i*4*h+j+0*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>12})
            pdf.box(50, i*4*h+j+1*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>14, :bold=>true})
            pdf.box(50, i*4*h+j+2*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>16, :italic=>true})
            pdf.box(50, i*4*h+j+3*h, 300, 20, 'Hello World!', :font=>{:family=>fs[i], :size=>18, :bold=>true, :italic=>true})
          end
        end
      end
      pdf.box(40, 40, 300, 60, "Heppo World! (Encadré)", :border=>{:color=>'#aaa'}, :background=>'#DEF', :font=>{:color=>'#75A', :size=>12})
      pdf.box(40, 40, 300, 60, "Heppo World! (Centré)", :border=>{:color=>'#aaa'}, :font=>{:color=>'#75A', :align=>'center middle', :size=>12})
      pdf.box(40, 40, 300, 60, "Heppo World! (Droite)", :border=>{:color=>'#aaa'}, :font=>{:color=>'#75A', :align=>'right bottom', :size=>12})
      pdf.box(40, 40, 150, 30, nil, :border=>{:color=>'#777'})


      #pdf.box(20,800, 400, 30, "ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει." * 20)
      
      pdf.box(40,     40+12, 80, 48, nil, :background=>'#777')
      pdf.box(40+110, 40,    80, 24, nil, :background=>'#778')
      pdf.box(40+110, 40+36, 80, 24, nil, :background=>'#779')
      pdf.box(40+220, 40,    80, 48, nil, :background=>'#77A')



      pdf.box(20,800, 400, 30, '\053'* 20)
    end





    pdf.generate :file=>'hebi.pdf'
  end
















  desc "Build a sample PDF with Prawn"
  task :prawn => :environment do
    require 'prawn'

    Prawn::Document.generate("prawn.pdf", :page_size => "A4") do
      
      #Prawn::Document.generate("utf8.pdf") do
      font "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"
      text "ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει." * 20

      #end
      
      pigs = "#{RAILS_ROOT}/vendor/plugins/xil/tasks/images/chrome.jpg"
#      image pigs, :at => [50,450], :width => 450                                      
      
      dice = "#{Prawn::BASEDIR}/data/images/dice.png"
#      image dice, :at => [50, 250], :scale => 0.75 



      bounding_box [100,600], :width => 200 do
        text "The rain in spain falls mainly on the plains " * 5
        stroke do
          line bounds.top_left,    bounds.top_right
          line bounds.bottom_left, bounds.bottom_right
        end
      end
      font "#{Prawn::BASEDIR}/data/fonts/Activa.ttf"
      bounding_box [300,600], :width => 200 do
        text "The rain in spain falls mainly on the plains. " * 8
        stroke do
          line bounds.top_left,    bounds.top_right
          line bounds.bottom_left, bounds.bottom_right
        end
      end
      
      bounding_box [100,500], :width => 200, :height => 200 do
        stroke do
          circle_at [100,100], :radius => 100
          line bounds.top_left, bounds.bottom_right
          line bounds.top_right, bounds.bottom_left
        end   
        
        bounding_box [50,150], :width => 100, :height => 100 do
          stroke_rectangle bounds.top_left, bounds.width, bounds.height
        end   
      end

      start_new_page :size=>[560, 560]



    end

  end



end
