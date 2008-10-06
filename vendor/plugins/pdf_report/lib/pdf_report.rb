
# This module groups the different methods allowing to obtain a PDF document.

module PdfReport

  def self.included (base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    
    require 'rexml/document'
    require 'digest/md5'
    require 'fpdf'

    include REXML
    

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
      options[:orientation] = (document_root.attributes['orientation'] || ORIENTATION.to_a[0][0]).to_sym
      raise Exception.new("Bad orientation in the template") unless ORIENTATION.include? options[:orientation]
      options[:unit]           = attribute(document_root, :unit, 'mm')
      options[:format]         = attribute(document_root, :format, 'A4')
      options['margin_top']    = attribute(document_root, 'margin-top', 5).to_f
      options['margin_bottom'] = attribute(document_root, 'margin-bottom', 5).to_f
      options[:block_y]        = 'b' # before_y
      options[:remaining]      = 'a' # after_y
      options[:available_height] = 'h' 
      options[:page_number]    = 'n' # page_number
      options[:count]          = 'm' # block_number in the current page
      options[:pdf]            = 'p' # FPDF object
      options[:now]            = 't' # timestamp NOW
      options[:id]             = 'i' # ID
      options[:depth]          = -1
      options[:permissions] = [:copy,:print]

      code ='def render_report_'+options[:name]+"("+options[:id]+")\n"
      code+=options[:now]+"=Time.now\n"
      code+=options[:pdf]+"=FPDF.new('"+ORIENTATION[options[:orientation]]+"','"+options[:unit]+"','" +options[:format]+ "')\n"
      code+=options[:pdf]+".set_protection(["+options[:permissions].collect{|x| ':'+x.to_s}.join(",")+"],'')\n"
      code+=options[:pdf]+".alias_nb_pages('[PAGENB]')\n"
      code+=options[:available_height]+"="+(format_height(options[:format],options[:unit])-options['margin_top']-options['margin_bottom']).to_s+"\n"
      code+=options[:page_number]+"=1\n"
      code+=options[:count]+"=0\n"
      code+=options[:pdf]+".set_auto_page_break(false)\n"

      options[:specials]      = [{}]
      options[:defaults]      = {"size"=>10, "family"=>'Arial', "color"=>'#000', "border-color"=>'#000', "border-width"=>0.2, "radius"=>0, "vertices"=>'1234'}.merge(document_root.attributes)

      code+=options[:pdf]+".set_font('"+options[:defaults]['family']+"','',"+options[:defaults]['size'].to_s+")\n"
      code+=options[:pdf]+".set_margins(0,0)\n"
      code+=options[:pdf]+".add_page()\n"
      code+=options[:block_y]+"="+options['margin_top'].to_s+"\n"
      code+=options[:remaining]+"="+options[:available_height]+"\n"
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
    def format_height(format, unit)
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
      attrs = loop.attributes
      
      if options[:depth]>=1 
        options[:specials][options[:depth]]={}
        options[:specials][options[:depth]][:header]=(options[:specials][options[:depth]-1][:header]).dup
        options[:specials][options[:depth]][:footer]=(options[:specials][options[:depth]-1][:footer]).dup
      end
      
      raise Exception.new("You must specify a name beginning by a character for the element loop (2 characters minimum): "+attrs['name'].to_s) unless attrs['name'].to_s=~/^[a-z][a-z0-9]+$/
      result=attrs["name"]
      
      options[:fields]={} if options[:fields].nil?
      query=attrs['query']
      
      if query
        if query=~/^SELECT\ [^;]*$/i
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each do |s| 
            options[:fields][result+'.'+s.downcase.strip] = result+"[\""+s.downcase.strip+"\"].to_s"
          end
          code+="for "+result+" in c.select_all('"+clean_string(query,options,true)+"')\n" 
        else
          raise Exception.new("Invalid SQL query. May be there is an SQL injection.")
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
            query = 'SELECT ('+condition+')::BOOLEAN AS x'
#            query = 
#            condition.gsub!("'","\\\\'")
#            options[:fields].each{ |f| condition.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'")}
            code+="if c.select_one(\'"+clean_string(query, options,true)+"\')[\"x\"]==\"t\"\n"
          end
          
          if element.name==XRL_BLOCK
            block_height = block_height(element)
            bhfe = block_height(options[:specials][depth][:footer][:even])
            bhfo = block_height(options[:specials][depth][:footer][:odd])
            
            code+="if("+options[:block_y]+"=="+options['margin_top'].to_s+")\n"+analyze_header(options)+"end\n" unless options[:specials].empty?
            
            if bhfe==bhfo
              code+="if("+options[:count]+"==0 and "+options[:remaining]+"<"+(block_height+bhfe).to_s+")\nraise Exception.new('Footer too big')\n"
              code+="elsif("+options[:remaining]+"<"+(block_height+bhfe).to_s+")\n"
            else
              code+="if("+options[:count]+"==0 and "+options[:remaining]+"<"+block_height.to_s+"+"+bhfe.to_s+" and "+options[:remaining]+"<"+bhfo.to_s+")\nraise Exception.new('Footer too big')\n"
              code+="elsif("+options[:remaining]+"<"+block_height.to_s+"+("+options[:page_number]+".even? ? "+bhfe.to_s+":"+bhfo.to_s+"))\n"
            end
            code+=analyze_page_break(element,options)+"\n"
            code+="end\n"
            code+=options[:count]+"+=1\n"
          end
          code+=self.send('analyze_'+ element.name.gsub("-","_"),element, options.dup) if [XRL_LOOP, XRL_BLOCK, XRL_PAGEBREAK].include?(element.name)
          code+="end\n" unless element.attributes['if'].nil?
        end
        
      end
      code+=analyze_footer(options) if options[:depth]==0
      code+="end\n" if query
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
        attrs=element.attributes
        case element.name
        when 'line'
          code+=options[:pdf]+".set_xy("+attrs['x1']+","+options[:block_y]+"+"+attrs['y1']+")\n"
        else
          code+=options[:pdf]+".set_xy("+attrs['x']+","+options[:block_y]+"+"+attrs['y']+")\n"
        end
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
        attrs = element.attributes
        case element.name
        when 'line'
          h=attrs['y1'].to_f>attrs['y2'].to_f ? attrs['y1'].to_f : attrs['y2'].to_f
        else
          h=attrs['y'].to_f+attrs['height'].to_f
        end
        height=h if h>height
      end
      h = block.attributes['height']||0
      return height>h ? height : h
    end 
    
    #
    def block_width(block)
      width=0
      block.each_element do |element|
        attrs = element.attributes
        case element.name
        when 'line'
          w=attrs['x1'].to_f>attrs['x2'].to_f ? attrs['x1'].to_f : attrs['x2'].to_f
        else
          w=attrs['x'].to_f+attrs['width'].to_f
        end
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
      code+=options[:count]+"=0\n"
      code+=options[:page_number]+"+=1\n"
      code+=options[:block_y]+"="+options['margin_top'].to_s+"\n"
      code+=options[:remaining]+"="+options[:available_height].to_s+"\n"
      code+=analyze_header(options)
      code.to_s
    end
    
    #
    def analyze_header(options={})
      code=""
      unless options[:specials].empty?
        unless options[:specials][options[:depth]].nil?
          unless options[:specials][options[:depth]][:header].nil?
            so = analyze_block(options[:specials][options[:depth]][:header][:odd],options)
            se = analyze_block(options[:specials][options[:depth]][:header][:even],options)
            if so!=se
              code+="if "+options[:page_number]+".even?\n"+se+"else\n"+so+"end\n"
            else
              code+=se
            end
          end
        end
      end
      code.to_s
    end
    
    #
    def analyze_footer(options={})
      code=""
      unless options[:specials].empty?
        unless options[:specials][options[:depth]].nil?
          unless options[:specials][options[:depth]][:footer].nil?
            so = analyze_block(options[:specials][options[:depth]][:footer][:odd],options)
            se = analyze_block(options[:specials][options[:depth]][:footer][:even],options)
            if so!=se
              code+="if "+options[:page_number]+".even?\n"
              code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:even]).to_s+"\n"
              code+=se
              code+="else\n"
              code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:odd]).to_s+"\n"
              code+=so
              code+="end\n"
            else
              code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:odd]).to_s+"\n"
              code+=se
            end

          end
        end
      end
      code.to_s
    end
    
    
    #  
    def analyze_text(text, options={})
      code=''
      attrs=text.attributes
#      raise Exception.new("Your text is out of the block") unless attrs['y'].to_i < attrs['width'].to_i
      color=attrs['color']||options[:defaults]['color']
      family=attrs['family']||options[:defaults]['family']
      size=attrs['size']||options[:defaults]['size']
      if attrs['border-color'] or attrs['border-width'] or attrs['background-color']
        code+=analyze_rectangle(text,options)
      end
      style = ''
      style += 'B' if attrs['weight']=='bold'
      style += 'U' if attrs['decoration']=='underline'
      style += 'I' if attrs['style']=='italic'
      code+=options[:pdf]+".set_text_color("+color_to_rvb(color)+")\n"
      code+=options[:pdf]+".set_font('"+family+"','"+style+"',"+size.to_s+")\n" 
      code+=options[:pdf]+".cell("+attrs['width']+","+attrs['height']+",'"+
        clean_string(text.text.to_s, options)+"',0,0,'"+attrs['align']+"',false)\n"
      code.to_s
    end 
    
    # 
    def analyze_image(image,options={})
      code=''
      attrs=image.attributes
      code+=options[:pdf]+".image('"+attrs['src']+"',"+attrs['x']+","+options[:block_y]+"+"+attrs['y']+","+attrs['width']+","+attrs['height']+")\n"   
      code.to_s
    end

    # 
    def analyze_line(line,options={})   
      code=''
      attrs=line.attributes
      border_color=attrs['border-color']||options[:defaults]['border-color']
      border_width=attrs['border-width']||options[:defaults]['border-width']
      code+=options[:pdf]+".set_draw_color("+color_to_rvb(border_color)+")\n"
      code+=options[:pdf]+".set_line_width("+border_width.to_s+")\n"
      code+=options[:pdf]+".line("+attrs['x1']+","+options[:block_y]+"+"+attrs['y1']+","+
        attrs['x2']+","+options[:block_y]+"+"+attrs['y2']+")\n"
      code.to_s
    end 
        
    #
    def analyze_rectangle(rectangle,options={})
      code=''
      attrs=rectangle.attributes 
      radius = attribute(rectangle,'radius',options[:defaults]['radius'])
      vertices = attribute(rectangle,'vertices',options[:defaults]['vertices'])
      style = ''
      if attrs['background-color']
        code+=options[:pdf]+".set_fill_color("+color_to_rvb(attrs['background-color'])+")\n"
        style += 'F'
      end
      if attrs['background-color'].nil? or attrs['border-color'] or attrs['border-width']
        border_color=attrs['border-color']||options[:defaults]['border-color']
        border_width=attrs['border-width']||options[:defaults]['border-width']
        code+=options[:pdf]+".set_line_width("+border_width.to_s+")\n" 
        code+=options[:pdf]+".set_draw_color("+color_to_rvb(border_color)+")\n"
        style += 'D'
      end
      code+=options[:pdf]+".rectangle("+attrs['x']+","+options[:block_y]+"+"+attrs['y']+
        ","+attrs['width']+","+attrs['height']+","+radius.to_s+",'"+style+"','"+vertices+"')\n"
      code.to_s
    end
    
    #
    def color_to_rvb(color)
      color="#"+color[1..1]*2+color[2..2]*2+color[3..3]*2 if color=~/^\#[a-f0-9]{3}$/i
      if color=~/^\#[a-f0-9]{6}$/i
        color[1..2].to_i(16).to_s+","+color[3..4].to_i(16).to_s+","+color[5..6].to_i(16).to_s  
      else
        '255,0,255' # Color which can be seen easily
      end
    end
    
    #
    def clean_string(string,options,query=false)
      string.gsub!("'","\\\\'")
      if query
        options[:fields].each{|f| string.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'")}
      else
        options[:fields].each{|f| string.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")}
      end
      while (string=~/[^\#]\{[A-Z\_].*.\}/)
        str = string.split('{')[1].split('}')[0]
        if str=~/CURRENT_DATE.*/ or str=~/CURRENT_TIMESTAMP.*/
          if (str.match ':').nil?
            format="%Y-%m-%d"
            format+=" %H:%M" if str=="CURRENT_TIMESTAMP"
          else
            format=str.split(':')[1]
          end
          string.gsub!("{"+str+"}",'\'+'+options[:now]+'.strftime(\''+format+'\')+\' ')
        elsif str=~/ID/
          string.gsub!("{"+str+"}",'\'+'+options[:id]+'.to_s+\'')
        elsif str=~/PAGENO/
          string.gsub!("{"+str+"}",'\'+'+options[:page_number]+'.to_s+\'')
        elsif str=~/PAGENB/
          string.gsub!("{"+str+"}",'[PAGENB]')
        end
      end
      Iconv.iconv('ISO-8859-15','UTF-8',string).to_s
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
      pdf=self.send('render_report_'+digest,id)
      Report.register(digest,id,pdf)
      pdf
    end
  end
end




