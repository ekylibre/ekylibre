module ApplicationHelper
  
  MENUS=
    [ 
     # CompanyController
     {:name=>:company, :list=>
       [ {:name=>:my_account, :list=>
           [{:name=>:user_statistics}, 
            {:name=>:change_password}
           ] },
         {:name=>:tools, :list=>
           [ {:name=>:backups},
             {:name=>:listings}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:configure},
             {:name=>:users},
             {:name=>:roles},
             {:name=>:establishments},
             {:name=>:departments},
             {:name=>:sequences},
             {:name=>:document_templates},
             {:name=>:document_natures}
           ] },
         {:name=>:informations, :list=>
           [ {:name=>:help},
             {:name=>:about_us}
           ] }
       ] },

     # RelationsController
     {:name=>:relations, :list=>
       [ {:name=>:entities_managing, :list=>
           [ {:name=>:entities},
             {:name=>:import_export, :url=>{:action=>:entities_import}},
             {:name=>:events},
             {:name=>:mandates}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:entities_natures},
             {:name=>:entity_link_natures},
             {:name=>:entity_categories},
             # {:name=>:meeting_locations},
             # {:name=>:meeting_modes},
             {:name=>:event_natures},
             {:name=>:complements},
             {:name=>:mandates_configure},
             {:name=>:areas},
             {:name=>:districts}
           ] }
       ] },
     # AccountancyController
     {:name=>:accountancy, :list=>
       [ {:name=>:works, :list=>
           [ {:name=>:entries},
             {:name=>:entries_consult},
             {:name=>:statements},
             {:name=>:lettering},
             # {:name=>:report},
             {:name=>:journal_close},
             {:name=>:financialyear_close} ] },
         {:name=>:documents, :list=>
           [ {:name=>:document_prepare} ] },
         {:name=>:parameters, :list=>
           [ {:name=>:accounts},
             {:name=>:journals},
             {:name=>:bank_accounts},
             {:name=>:taxes},
             {:name=>:financialyears} ] }
       ] },
     # ManagementController
     {:name=>:management, :list=>
       [ {:name=>:sale_orders, :list=>
           [ {:name=>:sale_order_create},
             {:name=>:sales_consult, :url=>{:action=>:sale_orders}},
             {:name=>:invoices},
             {:name=>:payments},
             {:name=>:embankments},
             {:name=>:subscriptions},
             {:name=>:statistics},
             {:name=>:transports}
           ] },
         {:name=>:purchase_orders, :list=>
           [ {:name=>:purchases_new},
             {:name=>:purchases_consult, :url=>{:action=>:purchase_orders}} ] },
         {:name=>:stocks, :list=>
           [ {:name=>:stock_location, :url=>{:action=>:stock_locations}},
             {:name=>:inventories},
             {:name=>:stock_transfers},
             {:name=>:stocks_consult, :url=>{:action=>:stocks}} ] },
         {:name=>:parameters, :list=>
           [ {:name=>:products},
             {:name=>:prices},
             {:name=>:shelves},
             {:name=>:delays},
             {:name=>:delivery_modes},
             {:name=>:payment_modes},
             {:name=>:sale_order_natures},
             {:name=>:subscription_natures}
           ] }
       ] },

     # ResourcesController
     {:name=>:resources, :list=>
       [ {:name=>:human, :list=>
           [ {:name=>:employees} ] },
         {:name=>:parameters, :list=>
           [ {:name=>:professions} ] }
       ] },

     # ProductionController
     {:name=>:production, :list=>
       [  {:name=>:production, :list=>
            [ {:name=>:productions},
              {:name=>:shape_operations}
            ] },
          {:name=>:parameters, :list=>
            [ {:name=>:shapes},
              {:name=>:shape_operation_natures}
            ] }
       ] }
     
    ]

  #raise Exception.new MENUS[0].inspect
  MENUS_ARRAY = MENUS.collect{|x| x[:name]  }
  

  
  def choices_yes_no
    [ [::I18n.translate('general.y'), true], [I18n.t('general.n'), false] ]
  end

  def menus
    MENUS
  end


  def link_to(*args, &block)
    if block_given?
      options      = args.first || {}
      html_options = args.second
      concat(link_to(capture(&block), options, html_options))
    else
      name         = args.first
      options      = args.second || {}
      html_options = args.third

      if options.is_a? Hash
        return "" unless controller.accessible?(options) 
      end

      url = url_for(options)
      if html_options
        html_options = html_options.stringify_keys
        href = html_options['href']
        convert_options_to_javascript!(html_options, url)
        tag_options = tag_options(html_options)
      else
        tag_options = nil
      end
      
      href_attr = "href=\"#{url}\"" unless href
      "<a #{href_attr}#{tag_options}>#{name || url}</a>"
    end
  end

  def li_link_to(*args)
    options      = args[1] || {}
    if controller.accessible?({:controller=>controller_name, :action=>action_name}.merge(options))
      content_tag(:li, link_to(*args))
    else
      ''
    end
  end
  
  def countries
    t('countries').to_a.sort{|a,b| a[1].ascii.to_s<=>b[1].ascii.to_s}.collect{|a| [a[1].to_s, a[0].to_s]}
  end

  def link_to_back(options={})
    #    link_to tg(options[:label]||'back'), :back
    link_to tg(options[:label]||'back'), session[:history][1]
  end
  #
  def elink(condition,label,url)
    link_to_if(condition,label,url) do |name| 
      content_tag :strong, name
    end
  end

  #
  def evalue(object, attribute, options={})
    value_class = 'value'
    if object.is_a? String
      label = object
      value = attribute
      value = value.to_s unless [String, TrueClass, FalseClass].include? value.class
    else
      #     label = object.class.human_attribute_name(attribute.to_s)
      value = object.send(attribute)
      label = t("activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}")
      label = t("activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}_id") if label.match(/translation.missing/)
      if value.is_a? ActiveRecord::Base
        record = value
        value = record.send(options[:label]||:name)
        options[:url][:id] ||= record.id if options[:url]
        # label = t "activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}_id"
      else
        # label = t "activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}"
      end
      value_class += ' code' if attribute.to_s == "code"
    end
    if [TrueClass, FalseClass].include? value.class
      value = image_tag('buttons/checkbox_'+value.to_s+'.png')
    end

    value = link_to(value.to_s, options[:url]) if options[:url]
    code  = content_tag(:div, label.to_s, :class=>:label)
    code += content_tag(:div, value.to_s, :class=>value_class)
    content_tag(:div, content_tag(:div,code), :class=>:evalue)
  end

  
  def last_page(controller)
    session[:last_page][controller]||url_for(:controller=>controller, :action=>:index)
  end

  def calendar_link_tag(lang='fr')
    # <script src="/red/javascripts/calendar/calendar.js" type="text/javascript"></script>
    # <script src="/red/javascripts/calendar/lang/calendar-fr.js" type="text/javascript"></script>
    # <script src="/red/javascripts/calendar/calendar-setup.js" type="text/javascript"></script>
    # , 'calendar/border-radius'
    javascript_include_tag('calendar/calendar', 'calendar/lang/calendar-'+lang, 'calendar/calendar-setup')+
      stylesheet_link_tag('calendar')
  end

  def calendar_field(object_name, method, options={})
    # <p><label for="issue_start_date">Début</label>
    # <input id="issue_start_date" name="issue[start_date]" size="10" type="text" value="2009-09-18" />
    # <img alt="Calendar" class="calendar-trigger" id="issue_start_date_trigger" src="/red/images/calendar.png" />
    # <script type="text/javascript">//<![CDATA[ Calendar.setup({inputField : 'issue_start_date', ifFormat : '%Y-%m-%d', button : 'issue_start_date_trigger' }); //]]>
    id = object_name.to_s+'_'+method.to_s
    text_field(object_name, method, {:size=>10}.merge(options))+
      image_tag('buttons/calendar.png', :class=>'calendar-trigger', :id=>id+'_trigger')+
      javascript_tag("Calendar.setup({inputField : '#{id}', ifFormat : '%Y-%m-%d', button : '#{id}_trigger' });")
  end

  def top_tag
    return '' if @current_user.blank?
    code = ''
    # Modules Tag
    tag = ''
    for m in MENUS
      # tag += elink(self.controller.controller_name!=m[:name].to_s, t("controllers.#{m[:name].to_s}.title"),{:controller=>m[:name]})+" "
      tag += elink(self.controller.controller_name!=m[:name].to_s, t("controllers.#{m[:name].to_s}.title"), last_page(m[:name].to_s))+" "
    end
    tag = content_tag(:nobr, tag)
    code += content_tag(:div, tag, :id=>:modules, :class=>:menu)
    # Fix
    tag = ''
    tag += image_tag('template/ajax-loader-3.gif', :id=>:loading, :style=>'display:none;')
    code += content_tag(:div, tag, :style=>'text-align:center;', :align=>:center, :flex=>1)
    
    # User Tag
    tag = ''

    tag += content_tag(:span, @current_user.label)+" "
    tag += content_tag(:span, @current_company.name)+" "
    tag += link_to(tc(:exit), {:controller=>:authentication, :action=>:logout}, :class=>:logout)+" "
    tag = content_tag(:nobr, tag)
    code += content_tag(:div, tag, :id=>:user, :class=>:menu, :align=>:right)
    
    # Fix
    code = content_tag(:div, code, :id=>:top, :orient=>:horizontal, :flexy=>true)
    code
  end

#   def modules_tag
#     tag = ''
#     for m in MENUS
#       tag += elink(self.controller.controller_name!=m[:name].to_s, t("controllers.#{m[:name].to_s}.title"),{:controller=>m[:name]})+" "
#     end
#     tag += image_tag('template/ajax-loader-3.gif', :id=>:loading, :style=>'display:none;')
#   end

#   def user_tag
#     tag = ''
#     tag += content_tag(:span, @current_user.label)+" "
#     tag += content_tag(:span, @current_company.name)+" "
#     tag += link_to(tc(:exit), {:controller=>:authentication, :action=>:logout}, :class=>:logout)+" "
#   end




  def side_tag(controller = self.controller.controller_name.to_sym)
    return '' if !MENUS_ARRAY.include?(self.controller.controller_name.to_sym)
    render(:partial=>'shared/menu', :locals=>{:menu=>MENUS.detect{|m| m[:name]==controller}})
  end

  def title
    t("views."+controller.controller_name+'.'+action_name+'.title', @title||{})
  end

  def help_link_tag
    return '' if @current_user.blank?
    options = {:class=>"help-link"} 
    url = {:controller=>:help, :action=>:search, :article=>controller.controller_name+'-'+action_name}
    content = content_tag(:div, '&nbsp;')
    options[:style] = "display:none" if session[:help]
    code = content_tag(:div, link_to_remote("Afficher l'aide", :update=>:help,  :url=>url, :complete=>"openHelp();", :loading=>"onLoading();", :loaded=>"onLoaded();"), {:id=>"help-open"}.merge(options))
  end

  def side_link_tag
    return '' unless @current_user
    return '' if !MENUS_ARRAY.include?(self.controller.controller_name.to_sym)
    code = content_tag(:div)
    operation = (session[:side] ? "close" : "open")
    link_to_remote(code, {:url=>{:controller=>:help, :action=>:side}, :loading=>"onLoading(); openSide();", :loaded=>"onLoaded();"}, :id=>"side-"+operation, :class=>"side-link")
  end


  def flash_tag(mode)
    content_tag(:div, flash[mode], :class=>'flash '+mode.to_s) if flash[mode]
  end

  def link_to_submit(form_name, label=:submit, options={})
    link_to_function(l(label), "document."+form_name+".submit()", options.merge({:class=>:button}))
  end



  def wikize(content, options={})
    without_paragraph = options.delete(:without_paragraph)
    options = {:url => {:controller=>:help, :action=>"search", :article=>'\1'}, :update => :help, :complete=>'resize2();'}.merge(options)
    
    # {{buttons/update.png|Label}}
    url = url_for(:controller=>:images)
    content = content.gsub(/\{\{([^\}]+)((\|)([^}]+))\}\}/, '!'+url+'/\1(\4)!')
    content = content.gsub(/\{\{([^\}]+)\}\}/, '!'+url+'/\1!' )
    # <<controller-action|Label>>
    ltr = link_to_remote('\4', options).gsub('%5C',"\\")
    content = content.gsub(/<<([\w\-]+)((\|)([^>]+))>>/ , ltr )
    # <<controller-action>>
    ltr = link_to_remote('\1', options).gsub('%5C',"\\")
    content = content.gsub(/<<([\w\-]+)>>/ , ltr )
    # content = content.squeeze(' ') # useless
    #      content = content.gsub(/(\ *)(\:|\?)/ , '~\2' )
    content.gsub!(/(\w)(\?|\:)([\s$])/ , '\1~\2\3' )
    content.gsub!(/[\s\~]+(\?|\:)/ , '~\1' )
    content.gsub!(/\~/ , '&nbsp;' )
    # Puts 2 EOL after a title
    content.gsub!(/(^h[0-9]\.\ [^\n]*\n)/ , "\\1\n")
    # raise Exception.new(content)
    content = without_paragraph ? textilize_without_paragraph(content) : textilize(content)
    content
  end


  def article(name, options={})
    name = name.to_s
    content = ''
    file_text = RAILS_ROOT+"/config/locales/"+I18n.locale.to_s+"/help/"+name+".txt"
    if File.exists?(file_text)  # the file doesn't exist in the cache, but exits as a text file
      File.open(file_text, 'r') do |file|
        content = file.read
      end
      content = wikize(content, options)
    end
    return content
  end

  

  def itemize(name, options={})
    code = '[EmptyItemizeError]'
    if block_given?
      list = Itemize.new(name)
      yield list
      code = itemize_to_html(list, options)
    end
    return code
  end


  def itemize_to_html(list, options={})
    cols = options[:cols]
    variable = instance_variable_get('@'+list.name.to_s)
    code = ''
    for item in list.items
      if item[:nature] == :item
        if item[:params].size==1
          code += evalue(variable, item[:params][0])
        end
      end
    end
    code = content_tag(:legend, list.name)+code
    code = content_tag(:fieldset, code, :class=>'itemize')
    code
  end

  class Itemize
    attr_reader :name, :items, :items_count, :stops_count

    def initialize(name)
      @name = name
      @items = []
      @items_count = 0
      @stops_count = 0
    end

    def item(*args)
      @items << {:nature=>:item, :params=>args}
      @items_count += 1
    end

    def stop(*args)
      @items << {:nature=>:stop, :params=>args}
      @stops_count += 1
    end
  end




  # TABBOX

  def tabbox(id)
    tb = Tabbox.new(id)
    yield tb
    tablabels = tabpanels = js = ''
    tabs = tb.tabs
    jsmethod = tb.id+'c'
    js += "function #{jsmethod}(id) {"
    tabs.size.times do |i|
      tab = tabs[i]
      js += "$('tp#{tab[:id]}').removeClassName('current');"
      js += "$('tl#{tab[:id]}').removeClassName('current');"
      tablabels += link_to_function(tab[:name].gsub(/\s+/,'&nbsp;'), "#{jsmethod}('#{tab[:id]}')", :class=>:tab, :id=>'tl'+tab[:id])+' '
      tabpanels += content_tag(:div, tab[:content], :class=>:tabpanel, :id=>'tp'+tab[:id])
    end
    js += "$('tp'+id).addClassName('current');"
    js += "$('tl'+id).addClassName('current');"
    js += "new Ajax.Request('#{url_for(:controller=>:company, :action=>:tabbox_index, :id=>tb.id)}?index='+id);"
    js += "return true;};"
    js += "#{jsmethod}('#{(session[:tabbox] ? session[:tabbox][tb.id] : nil)||tabs[0][:id]}');"
    code  = content_tag(:div, tablabels, :class=>:tabs)+content_tag(:div, tabpanels, :class=>:tabpanels)
    code += javascript_tag(js)
    content_tag(:div, code, :class=>:tabbox, :id=>tb.id)
  end


  class Tabbox
    attr_accessor :tabs, :id, :generated

    def initialize(id)
      @tabs = []
      @id = id.to_s
      @sequence = 0
    end

    def tab(name)
      content = []
      yield content if block_given?
      @tabs << {:name=>name, :content=>content.join, :id=>@id+(@sequence+=1).to_s}
    end

  end











  # TOOLBAR

  def toolbar(options={}, &block)
    code = '[EmptyToolbarError]'
    if block_given?
      toolbar = Toolbar.new
      if block
        if block.arity < 1
          self.instance_values.each do |k,v|
            toolbar.instance_variable_set("@"+k.to_s, v)
          end
          toolbar.instance_eval(&block)
        else
          block[toolbar] 
        end
      end
      toolbar.link :back if options[:back]
      # To HTML
      code = ''
      call = 'views.'+caller.detect{|x| x.match(/\/app\/views\//)}.split(/(\/app\/views\/|\.)/)[2].gsub(/\//,'.')+'.'
      for tool in toolbar.tools
        nature, args = tool[0], tool[1]
        if nature == :link
          name = args[0]
          args[1] ||= {}
          args[2] ||= {}
          if name.is_a? Symbol and name!=:back
            args[0] = t(call+name.to_s)
            args[1][:action] ||= name
            args[2][:class] = name.to_s.split('_')[-1]
          else
            args[2][:class] = args[1][:action].to_s.split('_')[-1] if args[1][:action]
          end
          
          code += li_link_to(*args)
        end
      end
      if code.strip.length>0
        code = content_tag(:ul, code)
        code = content_tag(:h2, t(call+options[:title].to_s))+code if options[:title]
        code = content_tag(:div, code, :class=>'toolbar'+(options[:class].nil? ? '' : ' '+options[:class].to_s))
      end
    else
      raise Exception.new('No block given for toolbar')
    end
    return code
  end

  class Toolbar
    attr_reader :tools

    def initialize()
      @tools = []
    end

    def link(*args)
      @tools << [:link, args]
    end
  end





  #
  #
  #                         F O R M A L I Z E
  #
  #
  def formalize(options={})
    code = '[EmptyFormalizeError]'
    if block_given?
      form = Formalize.new()
      yield form
      code = formalize_lines(form, options)
    end
    return code
  end


  # This methods build a form line after line
  def formalize_lines(form, form_options)
    code = ''
    controller = self.controller
    xcn = 2
    
    # build HTML
    for line in form.lines
      css_class = line[:nature].to_s
      
      # before line      
      # code += content_tag(:tr, content_tag(:th,'', :colspan=>xcn), :class=>"before-title") if line[:nature]==:title
      
      # line
      line_code = ''
      case line[:nature]
      when :error
        line_code += content_tag(:td,error_messages_for(line[:params]),:class=>"error", :colspan=>xcn)
      when :title
        #        reset_cycle "parity"
        if line[:value].is_a? Symbol
          calls = caller
          file = calls[3].split(/\:\d+\:/)[0].split('/')[-1].split('.')[0]
          #          file = file[1..-1] if file[0..0]=='_'
          line[:value] = t("views.#{controller.controller_name}.#{file}.#{line[:value]}") 
          #          line[:value] = t(line[:value]) 
        end
        line_code += content_tag(:th,line[:value].to_s, :class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>xcn)
      when :field
        #        css_class += ' '+cycle('odd', 'even', :name=>"parity")
        fragments = line_fragments(line)
        line_code += content_tag(:td, fragments[:label], :class=>"label")
        line_code += content_tag(:td, fragments[:input], :class=>"input")
        # line_code += content_tag(:td, fragments[:help],  :class=>"help")
      end
      unless line_code.blank?
        html_options = line[:html_options]||{}
        html_options[:class] = css_class
        code += content_tag(:tr, line_code, html_options)
      end
      
      # after line
      # code += content_tag(:tr, content_tag(:th,'', :colspan=>xcn), :class=>"after-title") if line[:nature]==:title
      
    end
    code = content_tag(:table, code, :class=>'formalize',:id=>form_options[:id])
    # code += 'error_messages_for ' ?
  end



  def line_fragments(line)
    help_tags = [:info, :example, :hint]
    fragments = {}

    help = ''
    for hs in help_tags
      line[hs] = translate_help(line, hs)
      #      help += content_tag(:div,l(hs, [content_tag(:span,line[hs].to_s)]), :class=>hs) if line[hs]
      help += content_tag(:div,t(hs), :class=>hs) if line[hs]
    end
    fragments[:help] = help

    #          help_options = {:class=>"help", :id=>options[:help_id]}
    #          help_options[:colspan] = 1+xcn-xcn*col if c==col-1 and xcn*col<xcn
    #label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
    #input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
    #help  = content_tag(:td, help,  :class=>"help",  :id=>options[:help_id])

    if line[:model] and line[:attribute]
      record = line[:model]
      method      = line[:attribute]
      options     = line

      record.to_sym if record.is_a?(String)
      object = record.is_a?(Symbol) ? instance_variable_get('@'+record.to_s) : record
      raise Exception.new('NilError on object: '+object.inspect) if object.nil?
      model = object.class
      raise Exception.new('ModelError on object (not an ActiveRecord): '+object.class.to_s) unless model.methods.include? "create"

      #      record = model.name.underscore.to_sym
      column = model.columns_hash[method.to_s]
      
      options[:field] = :password if method.to_s.match /password/
      
      input_id = object.class.name.tableize.singularize+'_'+method.to_s

      html_options = {}
      html_options[:size] = 24
      html_options[:class] = options[:class].to_s
      if column.nil?
        html_options[:class] += ' notnull' if options[:null]==false
        if method.to_s.match /password/
          html_options[:size] = 12
          options[:field] = :password if options[:field].nil?
        end
      else
        html_options[:class] += ' notnull' unless column.null
        unless column.limit.nil?
          html_options[:size] = column.limit if column.limit<html_options[:size]
          html_options[:maxlength] = column.limit
        end
        options[:field] = :checkbox if column.type==:boolean
        if column.type==:date
          options[:field] = :date 
          html_options[:size] = 10



# <p><label for="issue_start_date">Début</label><input id="issue_start_date" name="issue[start_date]" size="10" type="text" value="2009-09-18" /><img alt="Calendar" class="calendar-trigger" id="issue_start_date_trigger" src="/red/images/calendar.png" /><script type="text/javascript">
# //<![CDATA[ Calendar.setup({inputField : 'issue_start_date', ifFormat : '%Y-%m-%d', button : 'issue_start_date_trigger' }); //]]>

        end
      end
      
      if options[:choices].is_a? Hash
        options[:choices] = options[:choices].to_a.sort{|a,b| a[1]<=>b[1]}.collect{|x| x.reverse}
      end
      if options[:choices].is_a? Array
        options[:field] = :select if options[:field]!=:radio
        html_options.delete :size
        html_options.delete :maxlength
      end
      if options[:choices].is_a? Symbol
        options[:field] = :dyli
        html_options.delete :size
        html_options.delete :maxlength
      end

      options[:options] ||= {}
      input = case options[:field]
              when :password
                password_field record, method, html_options
              when :label
                record.send(method)
              when :checkbox
                check_box record, method, html_options
              when :select
                options[:choices].insert(0,[options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
                select record, method, options[:choices], options[:options], html_options
                #select " ", options[:choices], options[:options], html_options
              when :dyli
                dyli record, method, options[:choices], options[:options], html_options
              when :radio
                options[:choices].collect{|x| radio_button(record, method, x[1])+"&nbsp;"+content_tag(:label, x[0], :for=>input_id+'_'+x[1].to_s)}.join " "
              when :textarea
                text_area record, method, :cols => options[:options][:cols]||30, :rows => options[:options][:rows]||3, :class=>(options[:options][:cols]==80 ? :code : nil)
              when :date
                # date_text_field record, method, :order => [:day, :month, :year], :date_separator=>''
                calendar_field record, method
              else
                text_field record, method, html_options
              end
      #      input += content_tag(:strong, options[:field].to_s)
      if [:select, :dyli].include?(options[:field]) and options[:new].is_a? Hash
        label = tg(options[:new].delete(:label)||:new)
        input += link_to(label, options[:new], :class=>:fastadd)
      end
      # input += " "+tg("format_date.iso")+" " if options[:field] == :date


      #      input += content_tag(:h6,options[:field].to_s+' '+options[:choices].class.to_s+' '+options.inspect)
      
      label = t("activerecord.attributes.#{object.class.name.underscore}.#{method.to_s}")
      label = " " if options[:options][:hide_label] 
      
      #      label = if object.class.methods.include? "human_attribute_name"
      #                object.class.human_attribute_name(method.to_s)
      #              elsif record.is_a? Symbol
      #                t("activerecord.attributes.#{object.class.name.underscore}.#{method.to_s}")
      #              else
      #                tg(method.to_s)
      #              end          
      label = content_tag(:label, label, :for=>input_id) if object!=record
    elsif line[:field]
      label = line[:label]||'[NoLabel]'
      if line[:field].is_a? Hash
        options = line[:field].dup
        options[:options]||={}
        datatype = options[:datatype]
        options.delete :datatype
        name = options[:name]
        options.delete :name
        value = options[:value]
        options.delete :value
        input = case datatype
                when :boolean
                  hidden_field_tag(name, "0")+check_box_tag(name, "1", value, options)
                when :string
                  size = (options[:size]||0).to_i
                  if size>64
                    text_area_tag(name, value, :id=>options[:id], :maxlength=>size, :cols => 30, :rows => 3)
                  else
                    text_field_tag(name, value, :id=>options[:id], :maxlength=>size, :size=>size)
                  end
                when :radio
                  options[:choices].collect{ |x| radio_button_tag('radio', (x[1].eql? true) ? 1 : 0, false, :id=>'radio_'+x[1].to_s)+"&nbsp;"+content_tag(:label,x[0]) }.join(" ")
                when :choice
                  options[:choices].insert(0,[options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
                  content = select_tag(name, options_for_select(options[:choices], value), :id=>options[:id])
                  if options[:new].is_a? Hash
                    content += link_to(tg(options[:new].delete(:label)||:new), options[:new], :class=>:fastadd)
                  end
                  content
                when :record
                  model = options[:model]
                  instance = model.new
                  method_name = [:label, :native_name, :name, :to_s, :inspect].detect{|x| instance.respond_to?(x)}
                  choices = model.find_all_by_company_id(@current_company.id).collect{|x| [x.send(method_name), x.id]}
                  select_tag(name, options_for_select([""]+choices, value), :id=>options[:id])
                when :date
                  date_select(name, value, :start_year=>1980)
                when :datetime
                  datetime_select(name, value, :default=>Time.now, :start_year=>1980)
                else
                  text_field_tag(name, value, :id=>options[:id])
                end
        
      else
        input = line[:field].to_s
      end
    else
      raise Exception.new("Unable to build fragments without :model/:attribute or :field")
    end
    fragments[:label] = label
    fragments[:input] = input
    return fragments
  end
  

  def translate_help(options,nature,id=nil)
    t = nil
    if options[nature].nil? and id
      t = lh(controller.controller_name.to_sym, controller.action_name.to_sym, (id+'_'+nature.to_s).to_sym)
    elsif options[nature].is_a? Symbol
      t = lc(options[nature])
    elsif options[nature].is_a? String
      t = options[nature]
    end
    return t
  end
  
  
  
  class Formalize
    attr_reader :lines

    def initialize()
      @lines = []
    end

    def title(value, options={})
      @lines << options.merge({:nature=>:title, :value=>value})
    end

    def field(*params)
      #      @lines << {:nature=>:field, :params=>params}
      line = params[2]||{}
      #      line[:help] = 
      #      line.merge({:nature=>:field, :help=>params[2]})
      if params[1].is_a? Symbol
        line[:model] = params[0]
        line[:attribute] = params[1]
      else
        line[:label] = params[0]
        line[:field] = params[1]
      end
      line[:nature] = :field
      @lines << line
    end

    def error(*params)
      @lines << {:nature=>:error, :params=>params}
    end
  end


end



module SetColumnActiveRecord #:nodoc:
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  module ClassMethods

    def set_column(column, reference)
      code = ''
      col = column.to_s
      reflist = "#{col}_keys".upcase
      if reference.is_a? Hash
        #        code += "#{reflist} = {"+reference.collect{|x| ":"+x[0].to_s+"=>\""+x[1].to_s+"\""}.join(",")+"}\n"
        code += "#{reflist} = ["+reference.collect{|x| ":"+x[0].to_s}.join(",")+"]\n"
      elsif reference.is_a? Array
        #        code += "#{reflist} = {"+reference.collect{|x| ":"+x.to_s+"=>nil"}.join(",")+"}\n"
        code += "#{reflist} = ["+reference.collect{|x| ":"+x.to_s}.join(",")+"]\n"
      else
        reflist = reference.to_s
      end
      code << <<-"end_eval"
        def #{col}_include?(key)
          key = key.to_sym unless key.is_a?(Symbol)
          return false unless #{reflist}.include?(key)
            #          return !self.#{col}.to_s.match("(\ |^)"+key.to_s+"(\ |$)").nil?
            return #{col}_array.include?(key)
        end
        def #{col}_set(key,add=true)
          raise(Exception.new("Only Symbol are accepted")) unless key.is_a?(Symbol)
          return self.#{col} unless #{reflist}.include?(key)
            self.#{col}_array = (add ? self.#{col}_array << key : self.#{col}_array - [key])
            return self.#{col}
        end
        def #{col}_array
          self.#{col}.to_s.split(" ").collect{|key| key.to_sym if #{reflist}.include?(key.to_sym)}.compact
        end
        def #{col}_array=(array)
          self.#{col} = " "+array.flatten.uniq.collect{|key| key.to_sym if #{reflist}.include?(key.to_sym)}.compact.join(" ")+" "
        end
        end_eval
        #      ActionController::Base.logger.error(code)
        module_eval(code)
    end
  end
end

ActiveRecord::Base.send(:include, SetColumnActiveRecord)



module ActiveRecord
  class Base


    def merge(object, force=false)
      raise Exception.new("Unvalid object to merge: #{object.class}. #{self.class} expected.") if object.class != self.class
      reflections = self.class.reflections.collect{|k,v|  v if v.macro==:has_many}.compact
      if force
        for reflection in reflections
          klass = reflection.class_name.constantize 
          begin
            klass.update_all({reflection.primary_key_name=>self.id}, {reflection.primary_key_name=>object.id})
          rescue
            for item in object.send(reflection.name)
              begin
                item.send(reflection.primary_key_name.to_s+'=', self.id)
                item.send(:update_without_callbacks)
              rescue
                # If the item can't be attached, the item can't be.
                puts item.inspect
                klass.delete(item)
              end
            end
          end
        end
        object.delete
      else
        ActiveRecord::Base.transaction do
          for reflection in reflections
            reflection.class_name.constantize.update_all({reflection.primary_key_name=>self.id}, {reflection.primary_key_name=>object.id})
          end
          object.delete
        end
      end
      return self
    end

    def has_dependencies?
      
    end


  end
end



# module NewMethodsActiveRecord #:nodoc:
#   def self.included(base) #:nodoc:
#     base.extend(ClassMethods)
#   end
  
#   module ClassMethods

#     def merge(object)
#       raise Exception.new("Unvalid object to merge: #{object.class}. #{self.class} expected.") if object.class != self.class
#       reflections = self.class.reflections.collect{|k,v|  v if v.macro==:has_many}.compact
#       ActiveRecord::Base.transaction do
#         for reflection in reflections
#           reflection.class_name.constantize.update_all({reflection.primary_key_name=>self.id}, {reflection.primary_key_name=>object.id})
#         end
#         object.delete
#       end
#       return self
#     end

#   end
# end

# ActiveRecord::Base.send(:include, NewMethodsActiveRecord)



# Hack to clean textilize

module ActionView
  module Helpers #:nodoc:
    # The TextHelper module provides a set of methods for filtering, formatting
    # and transforming strings, which can reduce the amount of inline Ruby code in
    # your views. These helper methods extend ActionView making them callable
    # within your template files.
    module TextHelper
      begin
        require_library_or_gem "redcloth" unless Object.const_defined?(:RedCloth)
        def textilize(text, *rules)
          if text.blank?
            ""
          else
            rc = RedCloth.new(text, rules)
            rc.no_span_caps = true
            rc.to_html
          end
        end
      rescue LoadError
        # We can't really help what's not there
      end
    end
  end
end

