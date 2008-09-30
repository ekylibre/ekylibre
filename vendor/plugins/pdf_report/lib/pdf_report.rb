

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
    XRL_LINE='line'
    XRL_PAGEBREAK='page-break'
    XRL_RECTANGLE='rectangle'

    ORIENTATION = {:portrait=>'P', :landscape=>'L'}
    
    # this function begins to analyse the template extracting the main characteristics of
    # the Pdf document as the title, the orientation, the format, the unit ... 
    def analyze_template(template, options={})
      document=Document.new(template)
      document_root=document.root
      
      raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'
      code ='def render_report_'+options[:name]+"(id)\n"
      code+="now=Time.now\n"
      options[:orientation] = (document_root.attributes['orientation'] || ORIENTATION.to_a[0][0]).to_sym
      raise Exception.new("Bad orientation in the template") unless ORIENTATION.include? options[:orientation]
      options[:unit]           = attribute(document_root, :unit, 'mm')
      options[:format]         = attribute(document_root, :format, 'A4')
      options['margin_top']    = attribute(document_root, 'margin-top', 5).to_f
      options['margin_bottom'] = attribute(document_root, 'margin-bottom', 5).to_f
      options[:block_y]        = '_by' # before_y
      options[:remaining]      = '_ay' # after_y
      options[:page_height]    = '_ph' 
      options[:page_number]    = '_pn' # page_number
      options[:pdf]            = '_p'
      options[:depth]          = -1
      code+=options[:pdf]+"=FPDF.new('"+ORIENTATION[options[:orientation]]+"','"+options[:unit]+"','" +options[:format]+ "')\n"
      code+=options[:pdf]+".alias_nb_pages('[PAGENB]')\n"
      code+=options[:page_height]+"="+(page_height(options[:unit],options[:format])-options['margin_top']-options['margin_bottom']).to_s+"\n"
      code+=""+options[:page_number]+"=1\n"
      code+="count=0\n"
      code+=options[:pdf]+".set_auto_page_break(false)\n"

      options[:specials]      = [{}]
      options[:styles_origin] = {"size"=>14,"family"=>'Arial',"decoration"=>'none', "weight"=>'none', "color"=>'#000', "border-color"=>'#000', "border-width"=>0.2, "border-text"=>0 ,"background-color"=>'#DDD', "radius"=>"none","vertices"=>"1234","style"=>'none'}.merge(document_root.attributes)

      code+=options[:pdf]+".set_font('"+options[:styles_origin]['family']+"','',"+options[:styles_origin]['size'].to_s+")\n"
      code+=options[:pdf]+".set_margins(0,0)\n"
#      code+=options[:pdf]+".set_margins(0,"+options['margin_top'].to_s+")\n"
#      code+=options[:pdf]+".set_text_color("+color_to_rvb(styles_origin['color'])+")\n"
      code+=options[:pdf]+".add_page()\n"
      code+=options[:block_y]+"="+options['margin_top'].to_s+"\n"
      code+=options[:remaining]+"="+options[:page_height]+"\n"
      code+="c=ActiveRecord::Base.connection\n"
      code+=analyze_infos(document_root.elements[XRL_INFOS],options) if document_root.elements[XRL_INFOS]
      code+=analyze_loop(document_root.elements[XRL_LOOP],options) if document_root.elements[XRL_LOOP]
      code+=options[:pdf]+".Output()\n"
      code+="end" 

      module_eval(code)
      code
    end
    
    #
    def attribute(element, attribute, default=nil)
      if default.nil?
        element.attributes[attribute.to_s]
      else
        element.attributes[attribute.to_s]||default 
      end
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
      options[:depth] += 1
      code=''
      
      if options[:depth]>=1 
        options[:specials][options[:depth]]={}
        options[:specials][options[:depth]][:header]=(options[:specials][options[:depth]-1][:header]).dup
        options[:specials][options[:depth]][:footer]=(options[:specials][options[:depth]-1][:footer]).dup
      end
      
      raise Exception.new("You must specify a name beginning by a character for the element loop.") unless loop.attributes['name'] and loop.attributes['name'].to_s=~/^[a-z][a-z0-9]*$/      
      result=loop.attributes["name"]
      
      query=loop.attributes['query'] unless loop.attributes['query'].nil?
      
      options[:fields].each do |f| query.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless options[:fields].nil?
      
      if query
        unless (query=~/^SELECT.*.FROM/).nil?
          options[:fields]={} unless options[:fields]
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each{|s| options[:fields][result+'.'+s.downcase.strip]=result+"[\""+s.downcase.strip+"\"].to_s"}
          code+="for "+result+" in c.select_all('"+query+"')\n" 
        end
      else
        code+=result+"=[]\n"
      end

      loop.each_element do |element|
        depth=options[:depth]
        if (element.attributes['type']=='header' or element.attributes['type']=='footer')
          mode=attribute(element, :mode, 'all').to_sym
          type=attribute(element, :type, 'header').to_sym
          options[:specials]=[] unless options[:specials].is_a? Array
          options[:specials][depth]={} unless options[:specials][depth].is_a? Hash
          options[:specials][depth][type]={} unless options[:specials][depth][type].is_a? Hash
          if mode==:all
            options[:specials][depth][type][:even] = element.dup
            options[:specials][depth][type][:odd]  = options[:specials][depth][type][:even]
          else
            options[:specials][depth][type][mode] = element.dup
          end
          
        else          
          unless element.attributes['if'].nil?
            condition=element.attributes['if']
            condition.gsub!("'","\\\\'")
            options[:fields].each do |f| condition.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless options[:fields].nil?
            code+="if c.select_one(\'select ("+condition+")::boolean AS x\')[\"x\"]==\"t\"\n"
          end
          
          if element.name==XRL_BLOCK
            block_height = block_height(element)
            
            code+="if ("+options[:block_y]+"=="+options['margin_top'].to_s+")\n"+analyze_header(options)+"\nend\n" unless options[:specials].empty?
            code+="if(count==0 and "+options[:remaining]+"<"+block_height.to_s+"+"+block_height(options[:specials][depth][:footer][:even]).to_s+" and "+options[:remaining]+"<"+block_height.to_s+"+"+block_height(options[:specials][depth][:footer][:odd]).to_s+")\nraise Exception.new('Pied de page trop grand')\n"
            
            code+="elsif("+options[:remaining]+"<"+(block_height(element)).to_s+"+("+options[:page_number]+".even? ? "+block_height(options[:specials][depth][:footer][:even]).to_s+":"+block_height(options[:specials][depth][:footer][:odd]).to_s+"))\n"
            code+=analyze_page_break(element,options)+"\n"
            code+="end\n"
            code+="count+=1\n"
          end
          code+=self.send('analyze_'+ element.name.gsub("-","_"),element, options.dup) if [XRL_LOOP, XRL_BLOCK, XRL_PAGEBREAK].include? element.name and not ['header','footer'].include?(element.attributes["type"])
          code+="end\n" unless element.attributes['if'].nil?
        end
        
      end

      if options[:depth]==0 
        code+=analyze_footer(options)
      end
      code+="end \n" if query
      code.to_s
    end
    
    #     
    def analyze_block(block, options={})
      
      code=''
      block_height = block_height(block)
      
      # ca fonctionne
      #unless options[:format].split('x')[1].to_i >= block_height(block) and options[:format].split('x')[0].to_i >= block_width(block) 
      # raise Exception.new("Sorry, You have a block which bounds are incompatible with the format specified.")
      # puts block_width(block).to_s+"x"+block_height(block).to_s+":"+options[:format]
      #end
      
      block.each_element do |element|
        element_att=element.attributes
        code+=options[:pdf]+".set_xy("+element_att['x']+","+options[:block_y]+"+"+element_att['y']+")\n"
        code+=self.send('analyze_'+ element.name,element,options).to_s if [XRL_TEXT,XRL_IMAGE,XRL_LINE,XRL_RECTANGLE].include? element.name
      end
      
      code+=options[:block_y]+"+="+block_height.to_s+"\n"
      code+=options[:remaining]+"-="+block_height.to_s+"\n"
      code.to_s
    end 
    
    #
    def block_height(block)
      height=0
      block.each_element do |element|
        h=element.attributes['y'].to_i+element.attributes['height'].to_i
        height=h if h>height
      end
      h = block.attributes['height']||0
      return height>h ? height : h
    end 
    
    #
    def block_width(block)
      width=0
      block.each_element do |element|
        w=element.attributes['x'].to_i+element.attributes['width'].to_i
        width=w if w>width
      end
      w = block.attributes['width']||0
      return width>h ? width : w
    end 

    #
    def analyze_page_break(page_break,options={})
      code=""
      code+=analyze_footer(options)
      code+=options[:pdf]+".add_page()\n"
      code+="count=0\n"
      code+=options[:page_number]+"+=1\n"
      code+=options[:block_y]+"="+options['margin_top'].to_s+"\n"
      code+=options[:remaining]+"="+options[:page_height].to_s+"\n"
      code+=analyze_header(options)
      code.to_s
    end
    
    #
    def analyze_header(options={})
      code=""
      unless options[:specials].empty?
        code+="if "+options[:page_number]+".even?\n"
        code+=analyze_block(options[:specials][options[:depth]][:header][:even],options)
        code+="else\n"
        code+=analyze_block(options[:specials][options[:depth]][:header][:odd],options)
        code+="end\n" 
      end
      code.to_s
    end
    
    #
    def analyze_footer(options={})
      code=""
      code+="if "+options[:page_number]+".even?\n"
      code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:even]).to_s+"\n"
      code+=analyze_block(options[:specials][options[:depth]][:footer][:even],options)
      code+="else\n"
      code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:odd]).to_s+"\n"
      code+=analyze_block(options[:specials][options[:depth]][:footer][:odd],options)
      code+="end\n"
      code.to_s
    end
    
    
    #  
    def analyze_text(text, options={})
      code=''
      element_att=text.attributes
      raise Exception.new("Your text is out of the block") unless element_att['y'].to_i < element_att['width'].to_i
      data=text.text.gsub("'","\\\\'")
      options[:fields].each do |f| data.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")end unless options[:fields].nil?
      
      while data=~/[^\#]\{[A-Z\_].*.\}/ 
          str=data.split('{')[1].split('}')[0]
        analyze_constant(data,options[:pdf],str) 
      end
      
      border_text=element_att['border-text']||options[:styles_origin]['border-text']
      color=element_att['color']||options[:styles_origin]['color']
      style=element_att['style']||options[:styles_origin]['style']
      size=element_att['size']||options[:styles_origin]['size']
      weight=element_att['weight']||options[:styles_origin]['weight']
      decoration=element_att['decoration']||options[:styles_origin]['decoration']
      family=element_att['family']||options[:styles_origin]['family']
      
      code+=options[:pdf]+".set_text_color("+color_to_rvb(color)+")\n" unless element_att['color'].nil?
      code+=options[:pdf]+".set_font('"+family.to_s+"','"+(weight.first.upcase.to_s unless weight.include? 'none').to_s+(decoration.first.upcase.to_s unless decoration.include? 'none').to_s+(style.first.upcase.to_s unless style.include? 'none').to_s+"',"+size.to_s+")\n" 
      
      code+=analyze_rectangle(text,options) unless element_att['radius'].nil?

      code+=options[:pdf]+".cell("+element_att['width']+","+element_att['height']+",'"+Iconv.new('ISO-8859-15','UTF-8').iconv(data)+"',"+border_text.to_s+",0,'"+element_att['align']+"')\n"
#      code+=options[:pdf]+".set_font('"+options[:styles_origin]['family']+"','',"+options[:styles_origin]['size'].to_s+")\n"
#      code+=options[:pdf]+".set_text_color("+color_to_rvb(options[:styles_origin]['color'])+")\n" unless element_att['color'].nil?
      code.to_s
    end 
    
    # 
    def analyze_image(image,options={})
      code=''
      element_att=image.attributes
      code+=options[:pdf]+".image('"+element_att['src']+"',"+element_att['x']+","+options[:block_y]+"+"+element_att['y']+","+element_att['width']+","+element_att['height']+")\n"   
      code.to_s
    end

    # A revoir
    def analyze_line(line,options={})   
      code=''
      element_att=line.attributes
      right_border=element_att['x'].to_i+element_att['width'].to_i
#      border_color=element_att['border-color']||options[:styles_origin]['border_color']
#      code+=options[:pdf]+".set_draw_color("+color_to_rvb(border_color)+")\n"
      code+=options[:pdf]+".set_line_width("+element_att['height']+")\n"
      code+=options[:pdf]+".line("+element_att['x']+","+options[:block_y]+"+"+element_att['y']+","+right_border.to_s+","+options[:block_y]+"+"+element_att['y']+")\n"
      code.to_s
    end 
        
    #
    def analyze_rectangle(rectangle,options={})
      code=''
      element_att=rectangle.attributes 
      radius = element_att['radius']||options[:styles_origin]['radius']
      radius = 0 if radius.blank? or radius=="none"
      vertices=element_att['vertices']||options[:styles_origin]['vertices']
      border_color=element_att['border-color']||options[:styles_origin]['border-color']
      background_color=element_att['background-color']||options[:styles_origin]['background-color']
      border_width=element_att['border-width']||options[:styles_origin]['border-width']
#      code+="draw=fill=''\n"
#      draw='D' 
#      code+="fill='F'\n"
#      fill='F' 
      code+=options[:pdf]+".set_line_width("+border_width.to_s+")\n" 
      code+=options[:pdf]+".set_draw_color("+color_to_rvb(border_color)+")\n"
      code+=options[:pdf]+".set_fill_color("+color_to_rvb(background_color)+")\n"
      code+=options[:pdf]+".rectangle("+element_att['x']+","+options[:block_y]+"+"+element_att['y']+
        ","+element_att['width']+","+element_att['height']+","+radius.to_s+",'DF',"+vertices+")\n"
#      code+=options[:pdf]+".set_line_width("+options[:styles_origin]['border_width'].to_s+")\n" 
#      code+=options[:pdf]+".set_draw_color("+color_to_rvb(options[:styles_origin]['border_color'])+")\n";draw='D' 
      code.to_s
    end
    
    #
    def color_to_rvb(color)
      if color=~/^\#[a-f0-9]{3}$/i
        color="#"+color[1..1]*2+color[2..2]*2+color[3..3]*2
      end
      if color=~/^\#[a-f0-9]{6}$/i
        color[1..2].to_i(16).to_s+","+color[3..4].to_i(16).to_s+","+color[5..6].to_i(16).to_s  
      else
        '0,255,0'
      end
    end
    
    #
    def analyze_constant(data,pdf,str)
      code=''
      if str=~/CURRENT_DATE.*/ or str=~/CURRENT_TIMESTAMP.*/
        format="%Y-%m-%d"
        format+=" %H:%M" if str=="CURRENT_TIMESTAMP"
        format=str.split(':')[1] unless (str.match ':').nil?
        data.gsub!("{"+str+"}",' \'+now.strftime(\''+format+'\')+\' ')
      elsif str=~/ID/
        data.gsub!("{"+str+"}",'\'+id.to_s+\'')
      elsif str=~/PAGENO/
        data.gsub!("{"+str+"}",'\'+'+options[:page_number]+'.to_s+\'')
      elsif str=~/PAGENB/
        data.gsub!("{"+str+"}",'[PAGENB]')
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
      code=self.class.analyze_template(template, :name=>digest) unless self.methods.include? "render_report_#{digest}"
      f=File.open("/tmp/render_report_#{digest}.rb",'wb')
      f.write(code)
      f.close
      pdf=self.send('render_report_'+digest,id)
      
    end
  end
end




