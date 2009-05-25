require '../ebi'

pdf = Ebi.new(:encoding=>'UTF-8')
pdf.title = 'Enfin un moteur PDF lisible'
for angle in 0..1
  pdf.new_page([595.28, 841.89], angle*90)
  full = true
  if full
    pdf.image('images/ebimage3.jpg', 300, 20, :width=>275)
    pdf.image('images/ebimage3.jpg', 300, 300, :height=>100)
    pdf.image('images/ebimage1.jpg', 420, 300, :height=>100)
    pdf.image('images/ebimage4.png', 300, 600, :width=>275)
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
  
  pdf.box(40,     40+12, 80, 48, nil, :background=>'#777')
  pdf.box(40+110, 40,    80, 24, nil, :background=>'#778')
  pdf.box(40+110, 40+36, 80, 24, nil, :background=>'#779')
  pdf.box(40+220, 40,    80, 48, nil, :background=>'#77A')
  
  # pdf.box(40, 40, 300, 12, :border=>{:color=>'#777'})
  # pdf.box(40, 64, 300, 12, :border=>{:color=>'#777'})
  # pdf.box(40, 88, 300, 12, :border=>{:color=>'#777'})
end

pdf.generate :file=>'/tmp/test.pdf'
