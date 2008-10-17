# plugin XIL : XML-based Impression-template Language
# This module groups the different methods allowing to obtain a PDF document by the analyse of a template.

module Ekylibre
  module Xil

    def self.included (base)
      base.extend(ClassMethods)
      
    end

    module ClassMethods
      
      require 'rexml/document'
      require 'digest/md5'
      require 'fpdf'
      
      include REXML
      
      # Array listing the main options used by Xil plugin and specified here as a global variable.
      @@xil_options={:impression=>false, :impressions_path=>"#{RAILS_ROOT}/private/impressions", :subdir_size=>4096,
  :impression_model_name=>:impressions, :template_model_name=>:templates, :template=>false}
 #     @@xil_options={:features=>[:impression, :template], :impressions_path=>"#{RAILS_ROOT}/private/impressions", :subdir_size=>4096,
#  :impression_model_name=>:impressions, :template_model_name=>:templates}
   
      mattr_accessor :xil_options
      
      #List of constants for identify the balises
      XIL_TEMPLATE='template'
      XIL_TITLE='title'
      XIL_LOOP='loop'
      XIL_INFOS='infos'
      XIL_INFO='info'
      XIL_BLOCK='block'
      XIL_TEXT='text'
      XIL_IMAGE='image'
      XIL_LINE='line'
      XIL_PAGEBREAK='page-break'
      XIL_RECTANGLE='rectangle'
      
      ORIENTATION={:portrait=>'P', :landscape=>'L'}
      
      # this function begins to analyse the template extracting the main characteristics of
      # the Pdf document as the title, the orientation, the format, the unit ... 
      def analyze_template(template, options={})
        document=Document.new(template)
        document_root=document.root || (raise Exception.new("The template has not root."))
      
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
        options[:title]          = 'l' # title of the document
        options[:storage]        = 's' # path of the document storage
        options[:file]           = 'f' # file of the document sterage
        options[:temp]           = XIL_TITLE # temporary variable
        options[:key]            = 'k'
        options[:depth]          = -1
        options[:permissions]    = [:copy,:print]
       
        #puts @@xil[:template]
        if @@xil_options[:template]
          code ="def render_xil_"+options[:template_id].to_s 
        else
          code ="def render_xil_"+options[:name].to_s 
        end
        
        code+="_"+options[:output].to_s+"("+options[:key]+")\n"
        
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
        code+=analyze_title(document_root.elements[XIL_TITLE], options) if document_root.elements[XIL_TITLE]
        code+=analyze_infos(document_root.elements[XIL_INFOS],options) if document_root.elements[XIL_INFOS]
        code+=analyze_loop(document_root.elements[XIL_LOOP],options) if document_root.elements[XIL_LOOP]
        
        code+=options[:pdf]+"="+options[:pdf]+".Output() \n"
       
        if options[:archive]
          code+="binary_digest=Digest::SHA256.hexdigest("+options[:pdf]+")\n"
          code+="unless ::"+@@xil_options[:impression_model]+".exists?(['template_md5 = ? AND key = ? AND sha256 = ?','"+options[:name]+"',"+options[:key]+",'+binary_digest+'])\n"
          
          code+="impression=::"+@@xil_options[:impression_model]+".create!(:key=>"+options[:key]+",:template_md5=>'"+options[:name]+"', :sha256=>binary_digest, :original_name=>"+options[:title]+", :printed_at=>Time.now,:company_id=>"+options[:current_company].id.to_s+",
:filename=>'t')\n"
         puts @@xil_options[:subdir_size]
          code+=options[:storage]+"='"+@@xil_options[:impressions_path]+"/'+(impression.id/"+@@xil_options[:subdir_size].to_s+").to_i.to_s+'/'\n"
          code+="Dir.mkdir("+options[:storage]+") unless File.directory?("+options[:storage]+")\n"
          
          # creation of file and storage of code in. 
          code+=options[:file]+"=File.open("+options[:storage].to_s+"+impression.id.to_s,'wb')\n"
          code+=options[:file]+".write("+options[:pdf]+")\n"
          code+=options[:file]+".close()\n"
          
          code+="impression.filename="+options[:storage]+"+impression.id.to_s\n"
          code+="impression.save!\n"
          code+="end\n"
        end
                
        code+="send_data "+options[:pdf]+", :filename=>"+options[:title]+"\n"
        code+="end\n" 
        
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
      
      # this function test if the balise info exists in the template and adds it in the code	
      def analyze_infos(infos,options={})
        code=''
        infos.each_element(XIL_INFO) do |info|
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
      

      # this function test if the balise title exists in the template and adds it in the code	
      def analyze_title(title,options={})
        code=''
        query = title.attributes['query']
        
        if query=~/^SELECT\ [^;]*$/i
          result=options[:temp]
          options[:fields]={} if options[:fields].nil?
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each do |s|
            options[:fields][result+'.'+s.downcase.strip] = result+"[\""+s.downcase.strip+"\"].to_s" 
          end
          
          code+=result+"=c.select_one(\'"+clean_string(query, options,true)+"\')\n"
          
        end
        
        code+=options[:title]+"='"+clean_string(title.text,options)+"'\n"
        
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
            raise Exception.new("Invalid SQL query. Maybe there is an SQL injection.")
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
              code+="if c.select_one(\'"+clean_string(query, options,true)+"\')[\"x\"]==\"t\"\n"
            end
            
            if element.name==XIL_BLOCK
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
            code+=self.send('analyze_'+ element.name.gsub("-","_"),element, options.dup) if [XIL_LOOP, XIL_BLOCK, XIL_PAGEBREAK].include?(element.name)
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
          code+=self.send('analyze_'+ element.name,element,options).to_s if [XIL_TEXT,XIL_IMAGE,XIL_LINE,XIL_RECTANGLE].include? element.name
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
          elsif str=~/KEY/
            string.gsub!("{"+str+"}",'\'+'+options[:key]+'.to_s+\'')
          elsif str=~/TITLE/
            string.gsub!("{"+str+"}",'\'+'+options[:title]+'.to_s+\'')
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
end

# insertion of the module in the Actioncontroller
ActionController::Base.send :include, Ekylibre::Xil


module ActionController
  class Base
    
    # this function looks for a method render_xil_'template.id' _'output' and calls analyse_template if not.
    def render_xil(xil, options={}) 
      
      options[:archive]=Ekylibre::Xil::ClassMethods::xil_options[:impression] if options[:archive].nil?

      if xil.is_a? Integer
        
        raise Exception.new("No table Template exists.") if Ekylibre::Xil::ClassMethods::xil_options[:template]==false
        template= eval(Ekylibre::Xil::ClassMethods::xil_options[:template_model]).exists?(xil) ? eval(Ekylibre::Xil::ClassMethods::xil_options[:template_model]).find(xil).content : nil
        if not template.nil?
          template_id=xil  
          puts "Integer1:"+template_id.to_s
        else
          raise Exception.new('This ID has not been found in the database.') 
        end
        
      elsif xil.is_a? String

        if File.file? xil and (File.extname xil) == '.xml'
          f=File.open(xil,'rb')
          template=f.read.to_s
          f.close()
        elsif xil.start_with? '<?xml'
          template=xil
        else
          raise Exception.new("Error. The string is not correct.")
        end
        
        if Ekylibre::Xil::ClassMethods::xil_options[:template]
          
          template_id=eval(Ekylibre::Xil::ClassMethods::xil_options[:template_model]).exists?(['content =? ', template]) ? eval(Ekylibre::Xil::ClassMethods::xil_options[:template_model]).find(:first, :conditions => [ "content = ?", template]).id : nil
          puts "String1:"+template_id.to_s
          raise Exception.new("No record matching to the string has been found in the database.") if template_id.nil?
        end
        
      elsif xil.is_a? Template
        if Ekylibre::Xil::ClassMethods::xil_options[:template] 
          xil_temp=xil.split('id=')[1][0..0]
          template=Ekylibre::Xil::ClassMethods::xil_options[:template_model].exists?(xil_temp) ? Ekylibre::Xil::ClassMethods::xil_options[:template_model].find(xil_temp).content : nil
          if not template.nil?
            template_id=xil_temp
          else
            raise Exception.new('This record has not been found in the database.') 
          end
        else
          raise Exception.new("No table Template exists.")
        end  
        
      else
        raise Exception.new("Error of parameter : xil.")
      end  

      digest=Digest::MD5.hexdigest(template)
   
      unless not defined? @current_company 
        if Ekylibre::Xil::ClassMethods::xil_options[:template] 
          result=self.class.analyze_template(template, :template_id=>template_id, :name=>digest, :output=>options[:output], :archive=>options[:archive], :current_company=>@current_company) unless self.methods.include? "render_xil_"+template_id.to_s+"_"+options[:output].to_s  
        else
          result=self.class.analyze_template(template, :name=>digest, :output=>options[:output], :archive=>options[:archive], :current_company=>@current_company) unless self.methods.include? "render_xil_"+digest+"_"+options[:output].to_s  
        end
      end
      
      f=File.open('/tmp/test.rb', 'wb')
      f.write(result)
      f.close()
      
      if Ekylibre::Xil::ClassMethods::xil_options[:template] 
        self.send('render_xil_'+template_id.to_s+'_'+options[:output].to_s,options[:key])
      else
        self.send('render_xil_'+digest+'_'+options[:output].to_s,options[:key])
      end

    end


    # this function initializes the whole necessary environment for Xil. 
    def self.xil(options={})
      Ekylibre::Xil::ClassMethods::xil_options = Ekylibre::Xil::ClassMethods::xil_options.merge(options)
      new_options=Ekylibre::Xil::ClassMethods::xil_options
    
      # if a store of datas is implied by the user.
      if new_options[:impression]
        if new_options[:impression_model_name].is_a? Symbol
          new_options[:impression_model]=new_options[:impression_model_name].to_s.singularize.classify 
          
        else
          raise Exception.new("The name of impression is not a symbol.")
        end
        
        Dir.mkdir(new_options[:impressions_path]) unless File.directory?(new_options[:impressions_path])
        
        # creation of the list of folders necessaries to store documents impressions.
        array_id=eval(new_options[:impression_model]).find(:all) || (raise Exception.new("An error was occured during the loading of the #{new_options[:impression_model]} model."))
        
        (array_id.length).times do |id|
          Dir.mkdir(new_options[:impressions_path]+'/'+(id/new_options[:subdir_size]).to_s) unless File.directory?(new_options[:impressions_path]+'/'+(id/new_options[:subdir_size]).to_s)
        end
      end  
      
      # if the user wishes to load a model to make the impression (facture). 
      if new_options[:template]
        if new_options[:template_model_name].is_a? Symbol
          new_options[:template_model]=new_options[:template_model_name].to_s.singularize.classify 
        else
          raise Exception.new("The name of the template does not a string.")
        end
      end  

      Ekylibre::Xil::ClassMethods::xil_options=new_options
      
    end
    
  end
end






