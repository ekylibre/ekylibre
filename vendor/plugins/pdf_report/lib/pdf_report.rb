

# This module groups the different methods allowing to obtain a PDF document.

module PdfReport

  def self.included (base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    
    require 'rexml/document'
    include REXML
    require 'digest/md5'
    require 'rfpdf'
    

    #List of constants for identify the balises
    XRL_TEMPLATE='template'
    XRL_LOOP='loop'
    XRL_INFOS='infos'
    XRL_INFO='info'
    XRL_BLOCK='block'
    XRL_TEXT='text'
    XRL_IMAGE='image'
    XRL_RULE='rule'
    XRL_PAGEBREAK='page-break'
    XRL_RECTANGLE='rectangle'

    ORIENTATION = {:portrait=>'P', :landscape=>'L'}
    
    def attribute(element, attribute, default=nil)
      if default.nil?
        element.attributes[attribute.to_s]
      else
        element.attributes[attribute.to_s]||default 
      end
    end
    
    # this function begins to analyse the template extracting the main characteristics of
    # the Pdf document as the title, the orientation, the format, the unit ... 
    def analyze_template(template, options={})
      #def analyze_template(template, name, id)
      document=Document.new(template)
      document_root=document.root
#      va_r='mm'
      depth=0
      
      raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'
      code='def render_report_'+options[:name]+"(id)\n"
      code+="id="+options[:id].to_s+"\n"
      code+="now=Time.now\n"
      orientation = (document_root.attributes['orientation'] || ORIENTATION.to_a[0][0]).to_sym
      raise Exception.new("Bad orientation in the template") unless ORIENTATION.include? orientation
      unit = attribute(document_root, :unit, 'mm')
      format = attribute(document_root, :format, 'A4')
      margin_top    = attribute(document_root, 'margin-top', 15)
      margin_bottom = attribute(document_root, 'margin-bottom', 15)

      pdf='pdf'      
      code+=pdf+"=FPDF.new('"+ORIENTATION[orientation]+"','"+unit+"','" +format+ "')\n"
#      code+="page_number_total="+pdf+".alias_nb_pages()\n"      
      code+=pdf+".alias_nb_pages('{PAGENB}')\n"
      code+="page_height_origin="+(page_height(unit,format)-margin_top-margin-bottom).to_s+"\n"
      code+="page_number=1\n"
      code+=pdf+".set_auto_page_break(false)\n"
      code+=pdf+".set_font('Arial','B',14)\n"
      code+=pdf+".set_margins(0,"+margin_top.to_s+")\n"
      code+=pdf+".add_page()\n"
      code+="block_y="+margin_top.to_s+"\n"
      code+="page_height-=block_y\n"
      code+="c=ActiveRecord::Base.connection\n"
      code+=analyze_infos(document_root.elements[XRL_INFOS],:pdf=>pdf) if document_root.elements[XRL_INFOS]
      code+=analyze_loop(document_root.elements[XRL_LOOP],:pdf=>pdf,:depth=>depth,:format=>format, :margin_top=>margin_top, :margin_bottom=>margin_bottom) if document_root.elements[XRL_LOOP]
      code+=pdf+".Output()\n"
      code+="end" 

      module_eval(code)
      code
    end
    
    #
    def page_height(unit,format)
      coefficient = FPDF.scale_factor(unit)
      FPDF.format(format,coefficient)[1].to_f/coefficient
    end

    # this function test if the balise info exists in the template and add it in the code	
    def analyze_infos(infos,options={})
      
      code=''
      infos.each_element(XRL_INFO) do |info|
        case info.attributes['type']
          #   when "created-on"
          #    code += 'pdf.Set(\"#{info.text}\")'
        when "subject-on"
          code+=options[:pdf]+".set_subject('#{info.text}')\n"
        when "written-by"
          code+=options[:pdf]+".set_author('#{info.text}')\n"
        when "created-by"
          code+=options[:pdf]+".set_creator('#{info.text}')\n"
        end
      end
      code.to_s
    end
    
    # this function 	
    def analyze_loop(loop, options={})
      
      code=''
      
      raise Exception.new("You must specify a name for the element loop beginning by a character.") unless loop.attributes['name'] and loop.attributes['name'].to_s=~/^[a-z][a-z0-9]*$/      
      options[:result]=loop.attributes["name"]
      
      query=loop.attributes['query'] unless loop.attributes['query'].nil?
      
      options[:fields].each do |f| query.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless options[:fields].nil?
      
      
      if query
        unless (query=~/^SELECT.*.FROM/).nil?
          options[:fields]={}
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each{|s| options[:fields][options[:result]+'.'+s.downcase.strip]=options[:result]+"[\""+s.downcase.strip+"\"].to_s"}
          code+="for "+ options[:result]+" in c.select_all('"+query+"')\n" 
        end
      else
        code+=options[:result]+"='[]'\n"
      end

      loop.each_element do |element|
        if element.attributes['type'] and element.attributes['type']=='header'
          options[:header]=Hash.new unless options[:header].is_a? Hash
          options[:header][options[:depth]+1]=Hash.new unless options[:header][options[:depth]+1].is_a? Hash
          
          options[:header][options[:depth]+1][element.attributes['mode'] ? element.attributes['mode']:'all']=analyze_block(element,:pdf=>options[:pdf],:depth=>options[:depth]+1,:format=>options[:format],:fields=>options[:fields],:result=>options[:result])
          
        end
        
        unless element.attributes['if'].nil?
          condition=element.attributes['if']                
          condition.gsub!("'","\\\\'")
           options[:fields].each do |f| condition.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless options[:fields].nil?
           code+="if c.select_one(\'select ("+condition+")::boolean AS x\')[\"x\"]==\"t\"\n"
         end
      
       # code+="if block_y=="+margin_top.to_s+"\n"+analyze_header(:depth=>options[:depth],:header=>options[:header])+"\n" unless element.attributes['type'].nil?
          puts "#{element.name}: #{block_height(element)}"
          
          code+="if(page_height<"+block_height(element).to_s+")\n "+analyze_page_break(element,:pdf=>options[:pdf],:depth=>options[:depth]+1,:header=>options[:header])+"end\n"
          
          
          code+=self.send('analyze_'+ element.name,element,:pdf=>options[:pdf],:depth=>options[:depth]+1,:format=>options[:format],:fields=>options[:fields],:result=>options[:result]) unless [XRL_PAGEBREAK].include? element.name 
          
          code+="end\n" unless element.attributes['if'].nil?
          
          code+=self.send('analyze_page_break',element,:pdf=>options[:pdf],:depth=>options[:depth],:header=>options[:header]) if [XRL_PAGEBREAK].include? element.name 
        end
        
        code+="end \n" if query
        code.to_s
        
      end
      
      #     
      def analyze_block(block, options={})
        
        code=''
        width_block_depth=0 
        heigth_block_depth=0
        
        # ca fonctionne
        #unless options[:format].split('x')[1].to_i >= block_height(block) and options[:format].split('x')[0].to_i >= block_width(block) 
        # raise Exception.new("Sorry, You have a block which bounds are incompatible with the format specified.")
        # puts block_width(block).to_s+"x"+block_height(block).to_s+":"+options[:format]
        #end
        
        #unless block.attributes['if'].nil?
        # condition=block.attributes['if']                
        #condition.gsub!("'","\\\\'")
        #options[:fields].each do |f| condition.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless options[:fields].nil?
        #code+="if c.select_one(\'select ("+condition+")::boolean AS x\')[\"x\"]==\"t\"\n"
        #end
        
        #code+="if(page_height<"+block_height(block).to_s+")\n "+analyze_page_break(pdf,depth,header,fields,result)+"end\n"
        

        block.each_element do |element|
          attr_element=element.attributes
          code+=options[:pdf]+".set_xy("+attr_element['x']+",block_y+"+attr_element['y']+")\n"
          code+=self.send('analyze_'+ element.name,element,:pdf=>options[:pdf], :depth=>options[:depth], :fields=>options[:fields], :result=>options[:result]).to_s if [XRL_TEXT,XRL_IMAGE,XRL_RULE,XRL_RECTANGLE].include? element.name       
        end
        
        code+="block_y+="+block_height(block).to_s+"\n"
        code+="page_height-="+block_height(block).to_s+"\n"
        
        # code+="end\n" unless block.attributes['if'].nil?
        
        code.to_s
        
      end 
      
      #
      def block_height(block)
        height=0
        block.each_element do |element|
          h=element.attributes['y'].to_i+element.attributes['height'].to_i
          height=h if h>height
        end
        if block.attributes['height'].nil?
          return height
        else
          block=block.attributes['height']
          return (height>block ? height : block)
        end
      end 
      
      #
      def block_width(block)
        width=0
        block.each_element do |element|
          w=element.attributes['x'].to_i+element.attributes['width'].to_i
          width=w if w>width
        end
        if block.attributes['width'].nil?
          return width
        else
          block=block.attributes['width']
          return (width>block ? width:block)
        end
      end 

      def analyze_page_break(page_break,options={})
        code=''
        puts page_break
        #puts options[:header][options[:depth]].inspect
        #puts "\n" 
        
        code+=options[:pdf]+".add_page()\n page_number+=1\n block_y="+margin_top.to_s+"\n page_height=page_height_origin-block_y \n"
        #code+=analyze_header(:depth=>options[:depth],:header=>options[:header]) unless options[:header].empty?
        code.to_s
      end
      
      def analyze_header(options={})
        code=''
        #puts options[:header]
        #while options[:header].key?(options[:depth])==false do
        # options[:depth]-=1
        #end
        #code+="if page_number.even?\n"+options[:header][options[:depth]]['even']+"\n"+"else\n"+options[:header][options[:depth]]['odd']+"\n end\n"
        
        code.to_s
      end
      
      # 
      def analyze_rule(rule,options={})   
        code=''
        rule=rule.attributes
        right_border=rule['x'].to_i+ rule['width'].to_i
        code+=options[:pdf]+".set_line_width("+rule['height']+")\n"
        code+=options[:pdf]+".line("+rule['x']+",block_y+"+rule['y']+","+right_border.to_s+",block_y+"+rule['y']+") \n"
        code.to_s
      end 
      
      #  
      def analyze_text(text, options={})
        code=''
        raise Exception.new("Your text is out of the block") unless text.attributes['y'].to_i < text.attributes['width'].to_i
        data=text.text.gsub("'","\\\\'")
        text=text.attributes
        options[:fields].each do |f| data.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")end unless options[:fields].nil?
        while data=~/[^\#]\{[A-Z\_].*.\}/ 
            analyze_constant(data,options[:pdf],str = data.split('{')[1].split('}')[0])
        end
        code+=options[:pdf]+".set_text_color("+color_element(text,'color')+")\n" unless text['color'].nil?
        style=''
        style+=text['style'].first.upcase unless text['style'].nil?
        style+=text['decoration'].first.upcase unless text['decoration'].nil?
        style+=text['weight'].first.upcase unless text['weight'].nil?
        code+=options[:pdf]+".set_font('','"+style+"')\n" 
        code+=options[:pdf]+".cell("+text['width']+","+text['height']+",'"+Iconv.new('ISO-8859-15','UTF-8').iconv(data)+"',0,0,'"+text['align']+"')\n"
        code.to_s
      end 
      
      # 
      def analyze_image(image,options={})
        code=''
        image=image.attributes
        code+=options[:pdf]+".image('"+image['src']+"',"+image['x']+", block_y+"+image['y']+","+image['width']+","+image['height']+")\n"   
        code.to_s
      end
      
      def analyze_rectangle(rectangle,options={})
        code=''
        rectangle=rectangle.attributes
        code+="draw=fill=''\n"
        code+=options[:pdf]+".set_line_width("+rectangle['border-width']+")\n" unless rectangle['border-width'].nil?    
        code+=options[:pdf]+".set_draw_color("+color_element(rectangle,'border-color')+")\n";draw='D' unless rectangle['border-color'].nil?
        code+="fill='F'\n"+options[:pdf]+".set_fill_color("+color_element(rectangle,'background-color')+")\n";fill='F' unless rectangle['background-color'].nil?
        code+=options[:pdf]+".rectangle("+rectangle['x']+","+rectangle['y']+","+rectangle['width']+","+rectangle['height']+",10,'"+fill+draw+"')\n"
        code.to_s
      end
      
      #
      def color_element(element, attribute)
        color_table=(element[attribute]).split('#')[1].split('')
        return(color_table[0].hex*16).to_s+","+(color_table[1].hex*16).to_s+","+(color_table[2].hex*16).to_s  
      end
      
      #
      def analyze_constant(data,pdf,str)
        code=''
        if str=~/CURRENT_DATE.*/ or str=~/CURRENT_TIMESTAMP.*/
          #code+="now2=Time.now\n"
          format="%Y-%m-%d"
          format+=" %H:%M" if str=="CURRENT_TIMESTAMP"
          format=str.split(':')[1] unless (str.match ':').nil?
          
          data.gsub!("{"+str+"}",' \'+now.strftime(\''+format+'\')+\' ')
        elsif str=~/ID/
          data.gsub!("{"+str+"}",'\'+id.to_s+\'')
        elsif str=~/PAGENO/
          data.gsub!("{"+str+"}",'\'+page_number.to_s+\'')
#        elsif str=~/PAGENB/
#          data.gsub!("{"+str+"}",'\'+page_number_total.to_s+\'')
        end
        code.to_s
      end 
      
    end
    
  end

  # insertion of the module in the Actioncontroller
  ActionController::Base.send :include, PdfReport


  module ActionController
    class Base
      # this function looks for a method render_report_template and calls analyse_template if not.
      def render_report(template, id)
        raise Exception.new("Your argument template must be a string") unless template.is_a? String
        digest=Digest::MD5.hexdigest(template)
        #code=self.class.analyze_template(template, digest, id) unless self.methods.include? "render_report_#{digest}"
        code=self.class.analyze_template(template, :name=>digest, :id=>id) unless self.methods.include? "render_report_#{digest}"
        f=File.open("/tmp/render_report_#{digest}.rb",'wb')
        f.write(code)
        f.close
        puts code 
        pdf=self.send('render_report_'+digest,id)

      end
    end
  end




