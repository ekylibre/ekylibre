

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
    XRL_LOOP='loop'
    XRL_INFOS='infos'
    XRL_INFO='info'
    XRL_BLOCK='block'
    XRL_TEXT='text'
    XRL_IMAGE='image'
    XRL_RULE='rule'
    XRL_PAGEBREAK='page-break'
    XRL_RECTANGLE='rectangle'
    
   
    # this function begins to analyse the template extracting the main characteristics of
    # the Pdf document as the title, the orientation, the format, the unit ... 
    def analyze_template(template, name, id)
      document=Document.new(template)
      document_root=document.root
      va_r='mm'
      depth=0
      raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'   
      code=''
      code='def render_report_'+name+'(id)'+"\n"
      code+="id="+id.to_s+"\n"
      code+="now=Time.now\n"
      raise Exception.new("Bad orientation in the template") unless document_root.attributes['orientation'] || 'portrait' == 'portrait'
     
      pdf='pdf'
      
      code+=pdf+"=FPDF.new('P','"+ document_root.attributes['unit']+"','" + document_root.attributes['format']+ "')\n"
      code+=page_height(document_root)
      code+="page_height_origin=page_height\n"
      code+=pdf+".alias_nb_pages()\n"
      code+=pdf+".set_auto_page_break(false)\n"
      code+=pdf+".set_font('Arial','B',14)\n"
      code+=pdf+".set_margins(0,15)\n"
      code+=pdf+".add_page()\n"
      code+="block_y=15\n"
      code+="page_height-=block_y\n"
      code+=analyze_infos(document_root.elements[XRL_INFOS],pdf) if document_root.elements[XRL_INFOS]
      
     code+="c= ActiveRecord::Base.connection \n"+analyze_loop(document_root.elements[XRL_LOOP],pdf,depth,[]) if document_root.elements[XRL_LOOP]     
      code+=pdf+".Output()\n"

      code+="end" 

      module_eval(code)
      code
    end
    
    #
     def page_height(template)
       code=''
       template=template.attributes
       coefficient = FPDF.scale_factor(template['unit'])
       code+="page_height="+(FPDF.format(template['format'],coefficient)[1].to_f/coefficient-15).to_s+"\n"
       code.to_s 
     end

    # this function test if the balise info exists in the template and add it in the code	
    def analyze_infos(infos,pdf)
      code=''
      infos.each_element(XRL_INFO) do |info|
        case info.attributes['type']
          #   when "created-on"
          #    code += 'pdf.Set(\"#{info.text}\")'
        when "subject-on"
          code+=pdf+".set_subject('#{info.text}')\n"
        when "written-by"
          code+=pdf+".set_author('#{info.text}')\n"
        when "created-by"
          code+=pdf+".set_creator('#{info.text}')\n"
        end
      end
      code.to_s
    end
    
    # this function 	
    #def analyze_loop(loop, *params)
    def analyze_loop(loop,pdf, depth, header,fields=nil, result=nil)
      code=''
      
      raise Exception.new("You must specify a name for the element loop beginning by a character.") unless loop.attributes['name'] and loop.attributes['name'].to_s=~/^[a-z][a-z0-9]*$/
      

      result=loop.attributes["name"]
            
      query=loop.attributes['query'] unless loop.attributes['query'].nil?
      
      fields.each do |f| query.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless fields.nil?
      
     
      if query
        unless (query=~/^SELECT.*.FROM/).nil?
          fields={}
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each{|s| fields[result+'.'+s.downcase.strip]=result+"[\""+s.downcase.strip+"\"].to_s"}
          code+="for "+ result+" in c.select_all('"+query+"')\n" 
        end
      else
        code+=result+"='[]'\n"
      end  
      loop.each_element do |element|
        code+=self.send('analyze_'+ element.name,element,pdf,depth+1, header,fields, result) unless [XRL_PAGEBREAK].include? element.name 
       code+=self.send('analyze_page_break',pdf) if [XRL_PAGEBREAK].include? element.name 
      end
      
      code+="end \n" if query
      code.to_s
      
    end
    
    #     
    # def analyze_block(block, *params)
    def analyze_block(block,pdf, depth, header,fields=nil, result=nil)
      code=''
      width_block_depth=0 
      heigth_block_depth=0

      unless block.attributes['if'].nil?
        condition=block.attributes['if']                
        condition.gsub!("'","\\\\'")
        fields.each do |f| condition.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless fields.nil?
        code+="if c.select_one(\'select ("+condition+")::boolean AS x\')[\"x\"]==\"t\"\n"
      end
      
      code+="if(page_height<"+block_height(block).to_s+")\n "+analyze_page_break(pdf,depth,header)+"end\n"
     
      if block.attributes['type']=='header'
        header[depth]= Hash.new unless defined? header[depth]
        header[depth]={ 
          (block.attributes['mode'] ? block.attributes['mode'] : 'all') => { 
            "height" => block_height(block), "width"=> block_width(block), } 
        }
        #code+="mode=:"+(block.attributes['mode'] ? block.attributes['mode'] : 'all') + "\n" 
        #code+="\n"
      end 

      block.each_element do |element|
        attr_element=element.attributes
        code+=pdf+".set_xy("+attr_element['x']+",block_y+"+attr_element['y']+")\n"
        code+=self.send('analyze_'+ element.name,element,pdf, depth, fields, result).to_s if [XRL_TEXT,XRL_IMAGE,XRL_RULE,XRL_RECTANGLE].include? element.name       
      end
      code+="block_y+="+block_height(block).to_s+"\n"
      code+="page_height-="+block_height(block).to_s+"\n"
        
      

      code+="end\n" unless block.attributes['if'].nil?

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

    #
    def analyze_page_break(pdf,depth,header)
      code=''
      code+=pdf+".add_page()\n block_y=15\n page_height=page_height_origin-block_y \n"
      code+=analyze_header(pdf,depth,header)
      code.to_s
    end
    
    #
    def analyze_header(pdf,depth,header)
      code=''
      if header.has_key?(depth)
        header=header.fetch(depth)
      else
        
      end
      code.to_s
    end
    
    # 
    #def analyze_rule(rule,*params)   
    def analyze_rule(rule,pdf,depth,fields=nil,result=nil)   
     code=''
     rule=rule.attributes
     right_border=rule['x'].to_i+ rule['width'].to_i
     code+=pdf+".set_line_width("+rule['height']+")\n"
     code+=pdf+".line("+rule['x']+",block_y+"+rule['y']+","+right_border.to_s+",block_y+"+rule['y']+") \n"
     
     code.to_s
      
    end 
    
    #  
    #def analyze_text(text, *params)
    def analyze_text(text,pdf, depth,fields=nil, result=nil)
      code=''
      raise Exception.new("Your text is out of the block") unless text.attributes['y'].to_i < text.attributes['width'].to_i
      
      data=text.text.gsub("'","\\\\'")
      
      text=text.attributes
      
      fields.each do |f| data.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")end unless fields.nil?
      
      
      while data=~/[^\#]\{[A-Z\_].*.\}/ 
          analyze_constant(data,str=data.split('{')[1].split('}')[0])
      end

      code+=pdf+".set_text_color("+color_element(text,'color')+")\n" unless text['color'].nil?
      
      style=''
      style+=text['style'].first.upcase unless text['style'].nil?
      style+=text['decoration'].first.upcase unless text['decoration'].nil?
      style+=text['weight'].first.upcase unless text['weight'].nil?

      code+=pdf+".set_font('','"+style+"')\n" 

      code+=pdf+".cell("+text['width']+","+text['height']+",'"+Iconv.new('ISO-8859-15','UTF-8').iconv(data)+"',0,0,'"+text['align']+"')\n"
      
      code.to_s
      
    end 
    
    # 
    #def analyze_image(image,*params)
    def analyze_image(image,pdf,depth, fields=nil, result=nil)
      code=''
      image=image.attributes
      code+=pdf+".image('"+image['src']+"',"+image['x']+", block_y+"+image['y']+","+image['width']+","+image['height']+")\n"   
      code.to_s
    end
    
    #
    def analyze_rectangle(rectangle,pdf,depth,fields=nil,result=nil)
      code=''
      rectangle=rectangle.attributes
      code+="draw=fill=''\n"
      code+=pdf+".set_line_width("+rectangle['border-width']+")\n" unless rectangle['border-width'].nil?    
      code+=pdf+".set_draw_color("+color_element(rectangle,'border-color')+")\n";draw='D' unless rectangle['border-color'].nil?
      code+="fill='F'\n"+pdf+".set_fill_color("+color_element(rectangle,'background-color')+")\n";fill='F' unless rectangle['background-color'].nil?

      code+=pdf+".rectangle("+rectangle['x']+","+rectangle['y']+","+rectangle['width']+","+rectangle['height']+",10,'"+fill+draw+"')\n"
      code.to_s
    end
    
    #
    def color_element(element, attribute)
      color_table=(element[attribute]).split('#')[1].split('')
      return(color_table[0].hex*16).to_s+","+(color_table[1].hex*16).to_s+","+(color_table[2].hex*16).to_s  
    end
    
    #
    def analyze_constant(data,str)
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
        data.gsub!("{"+str+"}",'pageno.to_s')
      elsif str=~/PAGENB/
        data.gsub!("{"+str+"}",'pagenb.to_s')
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
      digest = Digest::MD5.hexdigest(template)
      code = self.class.analyze_template(template, digest, id) unless self.methods.include? "render_report_#{digest}"
      f = File.open("/tmp/render_report_#{digest}.rb",'wb')
      f.write(code)
      f.close
      #puts code 
      pdf = self.send('render_report_'+digest,id)
    end
  end
end




