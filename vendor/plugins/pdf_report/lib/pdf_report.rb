

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
    
    # this function begins to analyse the template extracting the main characteristics of
    # the Pdf document as the title, the orientation, the format, the unit ... 
    def analyze_template(template, options={})
      document=Document.new(template)
      document_root=document.root
      depth=-1
      
      raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'
      code='def render_report_'+options[:name]+"(id)\n"
      code+="id="+options[:id].to_s+"\n"
      code+="now=Time.now\n"
      orientation = (document_root.attributes['orientation'] || ORIENTATION.to_a[0][0]).to_sym
      raise Exception.new("Bad orientation in the template") unless ORIENTATION.include? orientation
      unit=attribute(document_root, :unit, 'mm')
      format=attribute(document_root, :format, 'A4')
      margin_top=attribute(document_root, 'margin-top', 15)
      margin_bottom=attribute(document_root, 'margin-bottom', 15)

      pdf='pdf'      
      code+=pdf+"=FPDF.new('"+ORIENTATION[orientation]+"','"+unit+"','" +format+ "')\n"
      code+=pdf+".alias_nb_pages('{PAGENB}')\n"
      code+="page_height_origin="+(page_height(unit,format)-margin_top-margin_bottom).to_s+"\n"
      code+="page_number=1\n"
      code+="count=0\n"
      code+=pdf+".set_auto_page_break(false)\n"
      code+=pdf+".set_font('Arial','B',14)\n"
      code+=pdf+".set_margins(0,"+margin_top.to_s+")\n"
      code+=pdf+".add_page()\n"
      code+="block_y="+margin_top.to_s+"\n"
      code+="page_height=page_height_origin\n"
      code+="c=ActiveRecord::Base.connection\n"
      code+=analyze_infos(document_root.elements[XRL_INFOS],:pdf=>pdf) if document_root.elements[XRL_INFOS]
      code+=analyze_loop(document_root.elements[XRL_LOOP],:pdf=>pdf,:depth=>depth,:format=>format, :margin_top=>margin_top, :margin_bottom=>margin_bottom, :specials=>[{}]) if document_root.elements[XRL_LOOP]
      code+=pdf+".Output()\n"
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
        options[:specials][options[:depth]]=options[:specials][options[:depth]-1].dup
      end
      
      puts options[:depth].to_s+" => "+options[:specials].inspect

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
        puts result+':'+element.name
        #  if element.attributes['type']=='specials'
        #           depth = options[:depth]
        #           options[:specials]=[] unless options[:specials].is_a? Array
        #           options[:specials][depth]={} unless options[:specials][depth].is_a? Hash
        #           mode = attribute(element, :mode, 'all').to_sym
        #           if mode==:all
        #             options[:specials][depth][:even] = analyze_block(element,options)
        #             options[:specials][depth][:odd]  = options[:specials][depth][:even]
        #           else
        #             options[:specials][depth][mode]=analyze_block(element,options)
        #           end  
        
        depth=options[:depth]
        if (element.attributes['type']=='header' or element.attributes['type']=='footer')
          mode=attribute(element, :mode, 'all').to_sym
          type=attribute(element, :type, 'header').to_sym
          puts type
          options[:specials]=[] unless options[:specials].is_a? Array
          options[:specials][depth]={} unless options[:specials][depth].is_a? Hash
          options[:specials][depth][type]={} unless options[:specials][depth][type].is_a? Hash
          if mode==:all
#            options[:specials][depth][type][:even] = analyze_block(element,options)
            options[:specials][depth][type][:even] = element.dup
            options[:specials][depth][type][:odd]  = options[:specials][depth][type][:even]
          else
            options[:specials][depth][type][mode] = element.dup
          end
          
          #elsif element.attributes['type']!='footer' # If it's a printable block or a loop
        else          
          unless element.attributes['if'].nil?
            condition=element.attributes['if']
            condition.gsub!("'","\\\\'")
            options[:fields].each do |f| condition.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless options[:fields].nil?
            code+="if c.select_one(\'select ("+condition+")::boolean AS x\')[\"x\"]==\"t\"\n"
          end
          #  puts options[:specials][depth][:footer].inspect
          
          #    code+="page_height_without_footer=page_height-"+block_height(options[:specials][depth][:footer][+"page_number.even? ? :even : :odd"]).to_s+"\n" unless options[:specials][depth][:footer].empty?
          
          
          #   code+="if (block_y"+block_height(element).to_s+">page_height_without_footer)\n"+options[:specials][depth][:footer][+"page_number.even? ? :even : :odd"]+analyze_page_header(element,options)+"\nend\n" unless options[:specials][depth][:footer].empty? 
          
          if element.name==XRL_BLOCK
            block_height = block_height(element)
            code+="if (block_y=="+options[:margin_top].to_s+")\n"+analyze_header(options)+"\nend\n" unless options[:specials].empty?
            code+="if(count==0 and page_height<"+block_height.to_s+"+"+block_height(options[:specials][depth][:footer][:even]).to_s+" and page_height<"+block_height.to_s+"+"+block_height(options[:specials][depth][:footer][:odd]).to_s+")\nraise Exception.new 'Pied de page trop grand'\n"
            code+="elsif(page_height<"+(block_height(element)).to_s+"+(page_number.even? "+block_height(options[:specials][depth][:footer][:even]).to_s+":"+block_height(options[:specials][depth][:footer][:odd]).to_s+")\n"+analyze_page_break(element,options)+"\n"
            code+="end\n"
            code+="count+=1\n"
          end
          
          code+=self.send('analyze_'+ element.name.gsub("-","_"),element, options.dup) if [XRL_LOOP, XRL_BLOCK, XRL_PAGEBREAK].include? element.name and not ['header','footer'].include?(element.attributes["type"])
          
          code+="end\n" unless element.attributes['if'].nil?
                
        end
        
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
          attr_element=element.attributes
          code+=options[:pdf]+".set_xy("+attr_element['x']+",block_y+"+attr_element['y']+")\n"
          code+=self.send('analyze_'+ element.name,element,options).to_s if [XRL_TEXT,XRL_IMAGE,XRL_RULE,XRL_RECTANGLE].include? element.name
        end
        code+="block_y+="+block_height.to_s+"\n"
        code+="page_height-="+block_height.to_s+"\n"
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
      def analyze_page_break(page_break,options={})
        code  = ""
        code += options[:pdf]+".add_page()\ncount=0\npage_number+=1\nblock_y="+options[:margin_top].to_s+"\n page_height=page_height_origin\n"
        code += analyze_header(options)
        code.to_s
      end
     
      #
      def analyze_header(options={})
        code  = ""
        
        unless options[:specials].empty?
          code += "if page_number.even?\n"+analyze_block(options[:specials][options[:depth]][:header][:even],options)
          code += "\nelse\n"+analyze_block(options[:specials][options[:depth]][:header][:odd],options)+"\nend\n" 
        end
        code.to_s
      end
      
      #
      # def analyze_footer(options={})
#         code  = ""
#         block_height(options[:specials][options[:depth]][:footer][+"page_number.even? ? :even : :odd"]).to_s+"\n" unless options[:specials].empty?
#         unless options[:specials].empty?
#           code += "if page_number.even?\n"+options[:specials][options[:depth]][:header][:even].to_s
#           code += "\nelse\n"+options[:specials][options[:depth]][:header][:odd].to_s+"\nend\n" 
#         end
#         code.to_s
#       end
 
      
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
      
      #
def analyze_rectangle(rectangle,options={})
        code=''
        rectangle=rectangle.attributes
        code+="draw=fill=''\n"
        code+=options[:pdf]+".set_line_width("+rectangle['border-width']+")\n" unless rectangle['border-width'].nil?    
        code+=options[:pdf]+".set_draw_color("+color_element(rectangle,'border-color')+")\n";draw='D' unless rectangle['border-color'].nil?
        code+="fill='F'\n"+options[:pdf]+".set_fill_color("+color_element(rectangle,'background-color')+")\n";fill='F' unless rectangle['background-color'].nil?
        code+=options[:pdf]+".rectangle("+rectangle['x']+",block_y+"+rectangle['y']+","+rectangle['width']+","+rectangle['height']+",10,'"+fill+draw+"')\n"
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
          format="%Y-%m-%d"
          format+=" %H:%M" if str=="CURRENT_TIMESTAMP"
          format=str.split(':')[1] unless (str.match ':').nil?
          
          data.gsub!("{"+str+"}",' \'+now.strftime(\''+format+'\')+\' ')
        elsif str=~/ID/
          data.gsub!("{"+str+"}",'\'+id.to_s+\'')
        elsif str=~/PAGENO/
          data.gsub!("{"+str+"}",'\'+page_number.to_s+\'')
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
        code=self.class.analyze_template(template, :name=>digest, :id=>id) unless self.methods.include? "render_report_#{digest}"
        f=File.open("/tmp/render_report_#{digest}.rb",'wb')
        f.write(code)
        f.close
        puts code 
  #      pdf=self.send('render_report_'+digest,id)
        
      end
    end
  end




