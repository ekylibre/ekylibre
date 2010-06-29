# -*- coding: utf-8 -*-
# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ##### END LICENSE BLOCK #####

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
             {:name=>:listings},
             {:name=>:import}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:configure},
             {:name=>:users},
             {:name=>:roles},
             {:name=>:document_templates},
             {:name=>:establishments},
             {:name=>:departments},
             {:name=>:sequences},
             {:name=>:units}
           ] },
         {:name=>:informations, :list=>
           [ {:name=>:help},
             {:name=>:about}
           ] }
       ] },

     # RelationsController
     {:name=>:relations, :list=>
       [ {:name=>:relations_tasks, :list=>
           [ {:name=>:entities},
             {:name=>:events},
             {:name=>:mandates}
           ] },
         {:name=>:tools, :list=>
           [ {:name=>:entities_import},
             {:name=>:entities_export}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:entity_categories},
             {:name=>:entity_natures},
             {:name=>:entity_link_natures},   
             {:name=>:event_natures},
             {:name=>:complements},
             {:name=>:mandates_configure},
             {:name=>:areas},
             {:name=>:districts}
           ] }
       ] },
     # AccountancyController
     {:name=>:accountancy, :list=>
       [ {:name=>:accountancy_tasks, :list=>
           [ {:name=>:journals},
             {:name=>:bank_statements},
             {:name=>:lettering},
             # {:name=>:document_print},
             # {:name=>:tax_declarations},
             {:name=>:accountize},
             {:name=>:financialyear_close}
           ] },
         {:name=>:documents, :list=>
           [ {:name=>:document_print},
             {:name=>:balance}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:accounts},
             {:name=>:financialyears},
             {:name=>:cashes},
             {:name=>:taxes} ] }
       ] },
     # ManagementController
     {:name=>:management, :list=>
       [ {:name=>:sales, :list=>
           [ {:name=>:sale_order_create},
             {:name=>:sale_orders},
             {:name=>:invoices},
             {:name=>:sale_payments},
             {:name=>:embankments},
             {:name=>:transports},
             {:name=>:subscriptions},
             {:name=>:statistics}
           ] },
         {:name=>:purchases, :list=>
           [ {:name=>:purchase_order_create},
             {:name=>:purchase_orders},
             {:name=>:purchase_payments}
           ] },
         {:name=>:stocks_tasks, :list=>
           [{:name=>:stocks},
            {:name=>:locations},
            {:name=>:stock_transfers},
            {:name=>:inventories}  
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:products},
             {:name=>:prices},
             {:name=>:shelves},
             {:name=>:delays},
             {:name=>:sale_payment_modes},
             {:name=>:purchase_payment_modes},
             {:name=>:delivery_modes},
             {:name=>:sale_order_natures},
             {:name=>:subscription_natures}
           ] }
       ] },


     # ProductionController
     {:name=>:production, :list=>
       [ {:name=>:production, :list=>
           [ {:name=>:operations},
             {:name=>:shapes}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:tools},
             {:name=>:operation_natures}
           ] }
       ] }
     #  ,
     # # ResourcesController
     # {:name=>:resources, :list=>
     #   [ {:name=>:human, :list=>
     #       [ {:name=>:employees} ] },
     #     {:name=>:parameters, :list=>
     #       [ {:name=>:professions} ] }
     #   ] }
     
    ]

  #raise Exception.new MENUS[0].inspect
  MENUS_ARRAY = MENUS.collect{|x| x[:name]  }
  

  
  def choices_yes_no
    [ [::I18n.translate('general.y'), true], [I18n.t('general.n'), false] ]
  end

  def radio_yes_no(name, value=nil)
    radio_button_tag(name, 1, value.to_s=="1", id=>"#{name}_1")+
      content_tag(:label, ::I18n.translate('general.y'), :for=>"#{name}_1")+
      radio_button_tag(name, 0, value.to_s=="0", id=>"#{name}_0")+
      content_tag(:label, ::I18n.translate('general.n'), :for=>"#{name}_0")
  end

  def radio_check_box(object_name, method, options = {}, checked_value = "1", unchecked_value = "0")
    # raise Exception.new eval("@#{object_name}.#{method}").inspect
    radio_button_tag(object_name, method, TrueClass, :id=>"#{object_name}_#{method}_#{checked_value}")+" "+
      content_tag(:label, ::I18n.translate('general.y'), :for=>"#{object_name}_#{method}_#{checked_value}")+" "+
      radio_button_tag(object_name, method, FalseClass, :id=>"#{object_name}_#{method}_#{unchecked_value}")+" "+
      content_tag(:label, ::I18n.translate('general.n'), :for=>"#{object_name}_#{method}_#{unchecked_value}")
  end

  def menus
    MENUS
  end

  def number_to_accountancy(value)
    number = value.to_f
    if number.zero?
      return ''
    else
      number_to_currency(number, :precision=>2, :format=>'%n', :delimiter=>'&nbsp;', :separator=>',')
    end
  end


  def parameter(name)
    # name = self.controller.controller_name.to_s+name.to_s if name.to_s.match(/^\./)
    @current_company.parameter(name)
  end

  def locale_selector
    select_tag("locale", options_for_select(::I18n.active_locales.sort{|a,b| a.to_s<=>b.to_s}.collect{|l| [::I18n.translate(l, :locale=>:languages), l]}, :selected=>::I18n.locale), :onchange=>remote_function(:url=>{:controller=>:application, :action=>:i18nize}, :with=>"'locale='+this.value", :success=>"window.location.replace('#{request.url}')"))
  end


  def svg_test_tag
    return '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full"><g fill-opacity="0.7" stroke="black" stroke-width="0.1cm"><circle cx="6cm" cy="2cm" r="100" fill="red" transform="translate(0,50)" /><circle cx="6cm" cy="2cm" r="100" fill="blue" transform="translate(70,150)" /><circle cx="6cm" cy="2cm" r="100" fill="green" transform="translate(-70,150)" /></g></svg>'
  end

  def link_to(*args, &block)
    if block_given?
      options      = args.first || {}
      html_options = args.second
      concat(link_to(capture(&block), options, html_options))
    else
      name         = args.first
      options      = args.second || {}
      html_options = args.third || {}

      if options.is_a? Hash
        return (html_options[:keep] ? "<a class='forbidden'>#{name}</a>" : "") unless controller.accessible?(options) 
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
    [[]]+t('countries').to_a.sort{|a, b| a[1].ascii.to_s<=>b[1].ascii.to_s}.collect{|a| [a[1].to_s, a[0].to_s]}
  end

  def languages
    I18n.valid_locales.collect{|x| [t("languages.#{x}"), x]}.to_a.sort{|a, b| a[0].ascii.to_s<=>b[0].ascii.to_s}
  end

  def link_to_back(options={})
    #    link_to tg(options[:label]||'back'), :back
    link_to tg(options[:label]||'back'), session[:history][1]
  end
  #

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
      default = ["activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}_id".to_sym]
      default << "activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s[0..-7]}".to_sym if attribute.to_s.match(/_label$/)
      label = ::I18n.translate("activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}".to_sym, :default=>default)
      if value.is_a? ActiveRecord::Base
        record = value
        value = record.send(options[:label]||[:label, :name, :code, :number, :inspect].detect{|x| record.respond_to?(x)})
        options[:url][:id] ||= record.id if options[:url]
        # label = t "activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}_id"
      else
        # label = t "activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}"
      end
      value_class += ' code' if attribute.to_s == "code"
    end
    if [TrueClass, FalseClass].include? value.class
      value = content_tag(:div, "", :class=>"checkbox-#{value}")
    elsif value.is_a? Date
      value = ::I18n.localize(value)
    elsif options[:duration]
      duration = value
      duration = duration*60 if options[:duration]==:minutes
      duration = duration*3600 if options[:duration]==:hours
      hours = (duration/3600).floor.to_i
      minutes = (duration/60-60*hours).floor.to_i
      seconds = (duration - 60*minutes - 3600*hours).round.to_i
      value = tg(:duration, :hours=>hours, :minutes=>minutes, :seconds=>seconds)
    end
    value = link_to(value.to_s, options[:url]) if options[:url]

    if options[:orient] == :vertical
      code  = content_tag(:tr, content_tag(:td, label.to_s, :class=>:label))
      code += content_tag(:tr, content_tag(:td, value.to_s, :class=>value_class))
      return content_tag(:table, code, :class=>"evalue verti")
    else
      code  = content_tag(:td, label.to_s, :class=>:label)
      code += content_tag(:td, value.to_s, :class=>value_class)
      return content_tag(:table, content_tag(:tr, code), :class=>"evalue hori")
    end
  end


  #   def sessany
  #     return (@current_company ? session[@current_company.code] ||= {} : session)
  #   end
  
  def last_page(controller)
    session[:last_page][controller]||url_for(:controller=>controller, :action=>:index)
  end




  # Permits to use themes for Ekylibre
  #  stylesheet_link_tag 'application', 'dyta', 'dyta-colors'
  #  stylesheet_link_tag 'print', :media=>'print'
  def theme_link_tag(name=nil)
    name ||= 'tekyla'
    code = ""
    for sheet, media in ["screen", "print", "dyta", "dyta-colors"]
      media = (sheet == "print" ? :print : :screen)
      if File.exists?("#{RAILS_ROOT}/public/themes/#{name}/stylesheets/#{sheet}.css")
        code += stylesheet_link_tag("/themes/#{name}/stylesheets/#{sheet}.css", :media=>media)
      end
    end
    return code
  end


  def theme_button(name, theme='tekyla')
    compute_public_path("#{name}.png", "themes/#{theme}/images/buttons")
  end


  # <script src="/red/javascripts/calendar/calendar.js" type="text/javascript"></script>
  # <script src="/red/javascripts/calendar/lang/calendar-fr.js" type="text/javascript"></script>
  # <script src="/red/javascripts/calendar/calendar-setup.js" type="text/javascript"></script>
  # , 'calendar/border-radius'
  def calendar_link_tag(lang='fr')
    javascript_include_tag('calendar/calendar', 'calendar/lang/calendar-'+lang, 'calendar/calendar-setup')+
      stylesheet_link_tag('calendar')
  end

  # <p><label for="issue_start_date">Début</label>
  # <input id="issue_start_date" name="issue[start_date]" size="10" type="text" value="2009-09-18" />
  # <img alt="Calendar" class="calendar-trigger" id="issue_start_date_trigger" src="/red/images/calendar.png" />
  # <script type="text/javascript">//<![CDATA[ Calendar.setup({inputField : 'issue_start_date', ifFormat : '%Y-%m-%d', button : 'issue_start_date_trigger' }); //]]>
  def calendar_field(object_name, method, options={})
    name = object_name.to_s+'_'+method.to_s
    text_field(object_name, method, {:size=>10}.merge(options))+
      image_tag(theme_button(:calendar), :class=>'calendar-trigger', :id=>name+'_trigger')+
      javascript_tag("Calendar.setup({inputField : '#{name}', ifFormat : '%Y-%m-%d', button : '#{name}_trigger' });")
  end

  def calendar_field_tag(name, value=Date.today, options={})
    options[:id] ||= name.to_s.gsub(/[\]\[]+/, '_').gsub(/_+$/, '')
    text_field_tag(name, value, {:size=>10}.merge(options))+
      image_tag(theme_button(:calendar), :class=>'calendar-trigger', :id=>options[:id]+'_trigger')+
      javascript_tag("Calendar.setup({inputField : '#{options[:id]}', ifFormat: '%Y-%m-%d', button : '#{options[:id]}_trigger' });")
  end




  def date_field(object_name, method, options={})
    name = object_name.to_s+'_'+method.to_s
    text_field(object_name, method, {:size=>10}.merge(options))+
      image_tag(theme_button(:calendar), :class=>'calendar-trigger', :id=>name+'_trigger')+
      javascript_tag("Calendar.setup({inputField : '#{name}', ifFormat : '%Y-%m-%d', button : '#{name}_trigger' });")
  end

  def date_field_tag(name, value=Date.today, options={})
    options[:id] ||= name.to_s.gsub(/[\]\[]+/, '_').gsub(/_+$/, '')
    text_field_tag(name, value, {:size=>10}.merge(options))+
      image_tag(theme_button(:calendar), :class=>'calendar-trigger', :id=>options[:id]+'_trigger')+
      javascript_tag("Calendar.setup({inputField : '#{options[:id]}', ifFormat: '%Y-%m-%d', button : '#{options[:id]}_trigger' });")
  end

  def datetime_field(object_name, method, options={})
    name = object_name.to_s+'_'+method.to_s
    text_field(object_name, method, {:size=>18}.merge(options))+
      image_tag(theme_button(:calendar), :class=>'calendar-trigger', :id=>name+'_trigger')+
      javascript_tag("Calendar.setup({inputField : '#{name}', showsTime : true, timeFormat : 24, ifFormat : '%Y-%m-%d %H:%M:%S', button : '#{name}_trigger' });")
  end

  def datetime_field_tag(name, value=Date.today, options={})
    options[:id] ||= name.to_s.gsub(/[\]\[]+/, '_').gsub(/_+$/, '')
    text_field_tag(name, value, {:size=>18}.merge(options))+
      image_tag(theme_button(:calendar), :class=>'calendar-trigger', :id=>options[:id]+'_trigger')+
      javascript_tag("Calendar.setup({inputField : '#{options[:id]}', showsTime : true, timeFormat : 24, ifFormat: '%Y-%m-%d %H:%M:%S', button : '#{options[:id]}_trigger' });")
  end


  def top_tag
    #return content_tag(:div, ' ', :style=>'display:none;') if @current_user.blank?
    #return '' if @current_user.blank?
    session[:last_page] ||= {}
    code = ''

    # User Tag
    tag = ''
    if @current_user
      # parameter = @current_user.parameter("interface.general.resized", true, :boolean)
      # tag += link_to("", {:resized=>(parameter.value.is_a?(TrueClass) ? "0" : "1")}, {:class=>:resize})+" "
      tag += content_tag(:span, @current_user.label)+" "
      tag += content_tag(:span, @current_company.name)+" "
      tag += link_to(tc(:exit), {:controller=>:authentication, :action=>:logout}, :class=>:logout)+" "
    end
    # tag = content_tag(:nobr, tag)
    code += content_tag(:div, tag, :id=>:user, :class=>:menu, :align=>:right)

    code += content_tag(:div, "", :id=>:loading, :style=>'display:none;')

    # Modules Tag
    tag = ''
    for m in MENUS
      if controller.accessible?({:controller=>m[:name]})
        tag += link_to_if(self.controller.controller_name!=m[:name].to_s, t("controllers.#{m[:name].to_s}.title"), last_page(m[:name].to_s)) do |name|
          link_to(name, {:controller=>m[:name], :action=>:index}, :class=>:current)
        end+" "
      end
    end if @current_user
    
    # tag = content_tag(:nobr, tag)
    code += content_tag(:div, tag, :id=>:modules, :class=>:menu)
  
    return code
    # Fix
    # code = content_tag(:div, code, :id=>:top, :orient=>:horizontal, :flexy=>true)
    # code
  end



  def action_title
    options = @title||{}
    return I18n.t("views.#{controller.controller_name}.#{action_name}.title", options)
  end

  def title_tag
    title = if @current_company
              tc(:title, :company_code=>@current_company.code, :company_name=>@current_company.name, :controller=>t("controllers.#{controller.controller_name}.title"), :action=>action_title)
            else
              tc(:default_title, :controller=>t("controllers.#{controller.controller_name}.title"), :action=>action_title)
            end
    return content_tag(:title, title)
  end

  def title_header_tag
    title = action_title
    content_tag(:h1, title, :class=>"title", :title=>title)
  end

  def help_link_tag(options={})
    return '' if @current_user.blank?
    options[:class] ||= ""
    options[:class] += " help-link help-open"
    options[:style] = "display:none" if session[:help]
    url = (options[:url]||{}).merge(:controller=>:help, :action=>:search, :article=>controller.controller_name+'-'+action_name)
    url[:dialog] = params[:dialog] if params[:dialog]
    update = (options.delete(:update)||:help).to_s
    return link_to_remote(tg(:display_help), {:update=>update, :url=>url, :complete=>h("toggleHelp('#{update}', true#{', \''+options[:resize].to_s+'\'' if options[:resize]});"), :loading=>"onLoading();", :loaded=>"onLoaded();"}, {:id=>"#{update}-open", :href=>url_for(url)}.merge(options))
  end

  def help_tag(html_options={})
    code = ''
    if session[:help]
      code = render(:partial=>'help/search')
    end
    # return content_tag(:div, code, {:id=>"help", :class=>"lm_right help", :style=>"#{'display:none;' unless session[:help]}; width: 240px;"}.merge(html_options))
    return code
  end

  def side_link_tag
    return '' unless @current_user
    return '' if !MENUS_ARRAY.include?(self.controller.controller_name.to_sym)
    code = content_tag(:div)
    operation = (session[:side] ? "close" : "open")
    link_to_remote(code, {:url=>{:controller=>:help, :action=>:side}, :loading=>"onLoading(); openSide();", :loaded=>"onLoaded();"}, :id=>"side-"+operation, :class=>"side-link")
  end

  def side_tag(controller = self.controller.controller_name.to_sym)
    return '' if !MENUS_ARRAY.include?(self.controller.controller_name.to_sym)
    render(:partial=>'shared/menu', :locals=>{:menu=>MENUS.detect{|m| m[:name]==controller}})
  end

  def notification_tag(mode)
    # content_tag(:div, flash[mode], :class=>'flash '+mode.to_s) unless flash[mode].blank?
    code = ''
    if flash[:notifications].is_a?(Hash) and flash[:notifications][mode].is_a?(Array)
      for message in flash[:notifications][mode]
        code += "<div class='flash #{mode}'><h3>#{tg('notifications.'+mode.to_s)}</h3><p>#{h(message).gsub(/\n/, '<br/>')}</p></div>"
      end
    end
    code
  end

  def notifications_tag
    return notification_tag(:error)+
      notification_tag(:warning)+
      notification_tag(:success)+
      notification_tag(:information)
  end

  def link_to_submit(form_name, label=:submit, options={})
    link_to_function(l(label), "document."+form_name+".submit()", options.merge({:class=>:button}))
  end


  def wikize(content, options={})
    # AJAX fails with XHTML entities because there is no DOCTYPE in AJAX response

    content.gsub!(/(\w)(\?|\:)([\s$])/ , '\1~\2\3' )
    content.gsub!(/[\s\~]+(\?|\:)/ , '~\1' )
    content.gsub!(/\~/ , '&#160;')

    content.gsub!(/^\ \ \*\ +(.*)\ *$/ , '<ul><li>\1</li></ul>')
    content.gsub!(/<\/ul>\n<ul>/ , '')
    content.gsub!(/^\ \ \-\ +(.*)\ *$/ , '<ol><li>\1</li></ol>')
    content.gsub!(/<\/ol>\n<ol>/ , '')
    content.gsub!(/^>>>\ +(.*)\ *$/ , '<p class="notice">\1</p>')
    content.gsub!(/<\/p>\n<p class="notice">/ , '<br/>')
    content.gsub!(/^!!!\ +(.*)\ *$/ , '<p class="warning">\1</p>')
    content.gsub!(/<\/p>\n<p class="warning">/ , '<br/>')

    content.gsub!(/\{\{\ *[^\}\|]+\ *(\|[^\}]+)?\}\}/) do |data|
      data = data.squeeze(' ')[2..-3].split('|')
      align = {'  '=>'center', ' x'=>'right', 'x '=>'left', 'xx'=>''}[(data[0][0..0]+data[0][-1..-1]).gsub(/[^\ ]/,'x')]
      title = data[1]||data[0].split(/[\:\\\/]+/)[-1].humanize
      src = data[0].strip
      if src.match(/^theme:/)
        src = compute_public_path(src.split(':')[1], "themes/#{@current_theme}/images") 
      else
        src = compute_public_path(src, "images") 
      end
      '<img class="md md-'+align+'" alt="'+title+'" title="'+title+'" src="'+src+'"/>'
    end


    content = content.gsub(/\[\[>[^\|]+\|[^\]]*\]\]/) do |link|
      link = link[3..-3].split('|')
      url = link[0].split(/[\/\?\&]+/)
      url = {:controller=>url[0], :action=>url[1]}
      (controller.accessible?(url) ? link_to(link[1], url) : link[1])
    end

    options[:url] ||= {}

    content = content.gsub(/\[\[[\w\-]+\|[^\]]*\]\]/) do |link|
      link = link[2..-3].split('|')
      options[:url][:article] = link[0]
      link_to_remote(link[1], options)
    end

    content = content.gsub(/\[\[[\w\-]+\]\]/) do |link|
      link = link[2..-3]
      options[:url][:article] = link
      link_to_remote(link, options)
    end

    for x in 1..6
      n = 7-x
      content.gsub!(/^\s*\={#{n}}\s*([^\=]+)\s*\={#{n}}/, "<h#{x}>\\1</h#{x}>")
    end

    content.gsub!(/^\ \ (.*\w+.*)$/, '  <pre>\1</pre>')

    content.gsub!(/([^\:])\/\/([^\s][^\/]+)\/\//, '\1<em>\2</em>')
    content.gsub!(/\'\'([^\s][^\']+)\'\'/, '<code>\1</code>')
    content.gsub!(/(^)([^\s\<][^\s].*)($)/, '<p>\2</p>')
    content.gsub!(/^\s*(\<a.*)\s*$/, '<p>\1</p>')

    content.gsub!(/\*\*([^\s\*]+)\*\*/, '<strong>\1</strong>')
    content.gsub!(/\*\*([^\s\*][^\*]*[^\s\*])\*\*/, '<strong>\1</strong>')
    content.gsub!(/(^|[^\*])\*([^\*]|$)/, '\1&lowast;\2')
    content.gsub!("</p>\n<p>", "\n")


    #raise Exception.new content
    return content
  end


  def article(name, options={})
    name = name.to_s
    content = ''
    file_text = RAILS_ROOT+"/config/locales/"+I18n.locale.to_s+"/help/"+name+".txt"
    unless File.exists?(file_text)
      file_text = RAILS_ROOT+"/config/locales/"+I18n.locale.to_s+"/help/"+name.gsub(/_[a-z0-9]+$/, '').pluralize+".txt" 
      unless File.exists?(file_text)
        file_text = RAILS_ROOT+"/config/locales/"+I18n.locale.to_s+"/help/"+name.pluralize+".txt" 
      end
    end
    if File.exists?(file_text)
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


  def tabbox(id, options={})
    tb = Tabbox.new(id)
    yield tb
    tablabels = tabpanels = js = ''
    tabs = tb.tabs
    tp, tl = 'p', 'l'
    jsmethod = "toggle"+tb.id.capitalize
    js += "function #{jsmethod}(index) {"
    tabs.size.times do |i|
      tab = tabs[i]
      js += "$('#{tab[:id]}#{tp}').removeClassName('current');"
      js += "$('#{tab[:id]}#{tl}').removeClassName('current');"
      tablabels += link_to_function((tab[:name].is_a?(Symbol) ? ::I18n.t("views.#{controller_name}.#{action_name}.#{tb.id}.#{tab[:name]}") : tab[:name]).gsub(/\s+/,'&nbsp;'), "#{jsmethod}(#{tab[:index]})", :class=>:tab, :id=>tab[:id]+tl)
      tabpanels += content_tag(:div, tab[:content]||render(:partial=>tab[:partial]), :class=>:tabpanel, :id=>tab[:id]+tp)
    end
    js += "$('#{tb.prefix}'+index+'#{tp}').addClassName('current');"
    js += "$('#{tb.prefix}'+index+'#{tl}').addClassName('current');"
    js += "new Ajax.Request('#{url_for(:controller=>:company, :action=>:tabbox_index, :id=>tb.id)}?index='+index);"
    js += "return true;};"
    js += "#{jsmethod}(#{(session[:tabbox] ? session[:tabbox][tb.id] : nil)||tabs[0][:index]});"
    code  = content_tag(:div, tablabels, :class=>:tabs)+content_tag(:div, tabpanels, :class=>:tabpanels)
    code += javascript_tag(js)
    content_tag(:div, code, :class=>options[:class]||"tabbox", :id=>tb.id)
  end


  class Tabbox
    attr_accessor :tabs, :id, :generated

    def initialize(id)
      @tabs = []
      @id = id.to_s
      @sequence = 0
      @separator = ""
    end

    def prefix
      @id+@separator
    end

    def tab(name, options={})
      @sequence += 1
      tabh = {:name=>name, :index=>@sequence, :id=>@id+@separator+@sequence.to_s}
      if block_given?
        array = []
        yield array
        tabh[:content] = array.join
      elsif options[:content]
        tabh[:content] = options[:content]
      else
        tabh[:partial] = options[:partial]||"#{@id}_#{name}"
      end
      @tabs << tabh
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
      call = 'views.'+caller.detect{|x| x.match(/\/app\/views\//)}.split(/\/app\/views\//)[1].split('.')[0].gsub(/\//,'.')+'.'
      for tool in toolbar.tools
        nature, args = tool[0], tool[1]
        if nature == :link
          name = args[0]
          args[1] ||= {}
          args[2] ||= {}
          args[2][:class] ||= name.to_s.split('_')[-1]
          if args[1].is_a? Hash and args[1][:remote]
            args[1].delete(:remote)
            args[1][:url] ||= {}
            if name.is_a? Symbol
              args[1][:url][:action] ||= name
              args[0] = ::I18n.t("#{call}#{name}".to_sym, :default=>["views.#{args[1][:url][:controller]||controller_name}.#{name}.title".to_sym]) 
            end
            if controller.accessible?({:controller=>controller_name, :action=>action_name}.merge(args[1][:url]))
              code += content_tag(:li, link_to_remote(*args))
            end
          else
            args[0] = ::I18n.t("#{call}#{name}".to_sym, :default=>["views.#{args[1][:controller]||controller_name}.#{name}.title".to_sym]) if name.is_a? Symbol
            if name.is_a? Symbol and name!=:back
              args[1][:action] ||= name
            else
              args[2][:class] = args[1][:action].to_s.split('_')[-1] if args[1][:action]
            end
            code += li_link_to(*args)
          end
        elsif nature == :print
          #raise Exception.new "ok"+args.inspect
          name = args[0].to_s
          args[2] ||= {}
          args[1] ||= {}
          args[1][:controller] = "company"
          args[1][:action] = "print"
          args[1][:p0] ||= args[1][:id]
          args[1][:id] = name
          args[1][:format] = "pdf"
          args[2][:class] = "print"
          #          raise Exception.new "ok"+args.inspect
          for dc in @current_company.document_templates.find_all_by_nature_and_active(name, true)
            args[0] = tc(:print, :name=>dc.name)
            args[1][:id] = dc.code
            #raise Exception.new "ok"
            code += li_link_to(*args)
          end
        elsif nature == :javascript
          name = args[0]
          args[0] = ::I18n.t("#{call}#{name}".to_sym) if name.is_a? Symbol
          args[2] ||= {}
          args[2][:class] ||= name.to_s.split('_')[-1]
          code += content_tag(:li, link_to_function(*args).to_s)
        elsif nature == :mail
          args[2] ||= {}
          args[2][:class] = :mail
          code += content_tag(:li, mail_to(*args).to_s)
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

    def javascript(*args)
      @tools << [:javascript, args]
    end

    def mail(*args)
      @tools << [:mail, args]
    end
    
    def print(*args)
      @tools << [:print, args]
    end
  end


  def error_messages(*params)
    params << {} unless params[-1].is_a? Hash
    params[-1][:class] = "flash error"
    params[-1][:header_tag] = "h3"
    error_messages_for(*params)
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
      line = params[2]||{}
      id = line[:id]||"ff"+Time.now.to_i.to_s(36)+rand.to_s[2..-1].to_i.to_s(36)
      if params[1].is_a? Symbol
        line[:model] = params[0]
        line[:attribute] = params[1]
      else
        line[:label] = params[0]
        line[:field] = params[1]
      end
      line[:nature] = :field
      line[:id] = id
      @lines << line
      return id
    end

    def error(*params)
      @lines << {:nature=>:error, :params=>params}
    end
  end


  def formalize(options={})
    if block_given?
      form = Formalize.new
      yield form
      formalize_lines(form, options)
    else
      '[EmptyFormalizeError]'
    end
  end


  protected

  # This methods build a form line after line
  def formalize_lines(form, form_options)
    code = ''
    controller = self.controller
    xcn = 2
    
    # build HTML
    for line in form.lines
      css_class = line[:nature].to_s
      
      # line
      line_code = ''
      case line[:nature]
      when :error
        line_code += content_tag(:td, error_messages(line[:params].to_s), :class=>"error", :colspan=>xcn)
      when :title
        if line[:value].is_a? Symbol
          calls = caller
          file = calls[3].split(/\:\d+\:/)[0].split('/')[-1].split('.')[0]
          options = line.dup
          options.delete_if{|k,v| [:nature, :value].include?(k)}
          line[:value] = t("views.#{controller.controller_name}.#{file}.#{line[:value]}", options) 
        end
        line_code += content_tag(:th,line[:value].to_s, :class=>"title", :id=>line[:value].to_s.lower_ascii, :colspan=>xcn)
      when :field
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
      
    end
    code = content_tag(:table, code, :class=>'formalize',:id=>form_options[:id])
    return code
  end



  def line_fragments(line)
    fragments = {}


    #     help_tags = [:info, :example, :hint]
    #     help = ''
    #     for hs in help_tags
    #       line[hs] = translate_help(line, hs)
    #       #      help += content_tag(:div,l(hs, [content_tag(:span,line[hs].to_s)]), :class=>hs) if line[hs]
    #       help += content_tag(:div,t(hs), :class=>hs) if line[hs]
    #     end
    #     fragments[:help] = help

    #          help_options = {:class=>"help", :id=>options[:help_id]}
    #          help_options[:colspan] = 1+xcn-xcn*col if c==col-1 and xcn*col<xcn
    #label = content_tag(:td, label, :class=>"label", :id=>options[:label_id])
    #input = content_tag(:td, input, :class=>"input", :id=>options[:input_id])
    #help  = content_tag(:td, help,  :class=>"help",  :id=>options[:help_id])

    if line[:model] and line[:attribute]
      record  = line.delete(:model)
      method  = line.delete(:attribute)
      options = line

      record.to_sym if record.is_a?(String)
      object = record.is_a?(Symbol) ? instance_variable_get('@'+record.to_s) : record
      raise Exception.new("Object #{record.inspect} is "+object.inspect) if object.nil?
      model = object.class
      raise Exception.new('ModelError on object (not an ActiveRecord): '+object.class.to_s) unless model.methods.include? "create"

      #      record = model.name.underscore.to_sym
      column = model.columns_hash[method.to_s]
      
      options[:field] = :password if method.to_s.match /password/
      
      input_id = object.class.name.tableize.singularize+'_'+method.to_s

      html_options = {}
      html_options[:size] = options[:size]||24
      html_options[:onchange] = options[:onchange] if options[:onchange]
      html_options[:class] = options[:class].to_s
      if column.nil?
        html_options[:class] += ' notnull' if options[:null]==false
        if method.to_s.match /password/
          html_options[:size] = 12
          options[:field] = :password if options[:field].nil?
        end
      else
        html_options[:class] += ' notnull' unless column.null
        html_options[:size] = 16 if column.type==:integer
        unless column.limit.nil?
          html_options[:size] = column.limit if column.limit<html_options[:size]
          html_options[:maxlength] = column.limit
        end
        options[:field] = :checkbox if column.type==:boolean
        if column.type==:date
          options[:field] = :date 
          html_options[:size] = 10
        elsif column.type==:datetime or column.type==:timestamp
          options[:field] = :datetime
        end
      end

      options[:options] ||= {}
      
      if options[:choices]
        html_options.delete :size
        html_options.delete :maxlength
        rlid = options[:id]
        if options[:choices].is_a? Array
          options[:field] = :select if options[:field]!=:radio
        elsif options[:choices].is_a? Hash
          options[:field] = :dyselect
          html_options[:id] = rlid
        elsif options[:choices].is_a? Symbol
          options[:field] = :dyli
          options[:options][:field_id] = rlid
        else
          raise ArgumentError.new("Option :choices must be Array, Symbol or Hash (got #{options[:choices].class.name})")
        end
      end

      input = case options[:field]
              when :password
                password_field(record, method, html_options)
              when :label
                object.send(method)
              when :checkbox
                check_box(record, method, html_options)
              when :select
                options[:choices].insert(0, [options[:options].delete(:include_blank), '']) if options[:options][:include_blank].is_a? String
                select(record, method, options[:choices], options[:options], html_options)
              when :dyselect
                select(record, method, @current_company.reflection_options(options[:choices]), options[:options], html_options)
              when :dyli
                dyli(record, method, options[:choices], options[:options], html_options)
              when :radio
                options[:choices].collect{|x| radio_button(record, method, x[1])+"&nbsp;"+content_tag(:label, x[0], :for=>input_id+'_'+x[1].to_s)}.join(" ")
              when :textarea
                text_area(record, method, :cols => options[:options][:cols]||30, :rows => options[:options][:rows]||3, :class=>(options[:options][:cols]==80 ? :code : nil))
              when :date
                date_field(record, method)
              when :datetime
                datetime_field(record, method)
              else
                text_field(record, method, html_options)
              end

      if options[:new].is_a?(Hash) and [:select, :dyselect, :dyli].include?(options[:field])
        label = tg(options[:new].delete(:label)||:new)
        if options[:field] == :select
          input += link_to(label, options[:new], :class=>:fastadd, :confirm=>::I18n.t('notifications.you_will_lose_all_your_current_data')) unless request.xhr?
        elsif controller.accessible?(options[:new])
          if options[:field] == :dyselect
            data = "refreshList('#{rlid}', request, '#{url_for(options[:choices].merge(:controller=>:company, :action=>:formalize))}');"
          else
            data = "refreshAutoList('#{rlid}', request);"
          end
          data = ActiveSupport::Base64.encode64(Marshal.dump(data))
          input += link_to_function(label, "openDialog('#{url_for(options[:new].merge(:formalize=>data))}')", :href=>url_for(options[:new]), :class=>:fastadd)
        end
      end
      
      label = t("activerecord.attributes.#{object.class.name.underscore}.#{method.to_s}")
      label = " " if options[:options][:hide_label] 
      label = content_tag(:label, label, :for=>input_id) if object!=record
    elsif line[:field]
      label = line[:label]||'[NoLabel]'
      if line[:field].is_a? Hash
        options = line[:field].dup
        options[:options]||={}
        datatype = options.delete(:datatype)
        name  = options.delete(:name)
        value = options.delete(:value)
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
                  options[:choices].collect{ |x| radio_button_tag(name, x[1], (value.to_s==x[1].to_s), :id=>"#{name}_#{x[1]}")+"&nbsp;"+content_tag(:label,x[0], :for=>"#{name}_#{x[1]}") }.join(" ")
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
      t = tc(options[nature])
    elsif options[nature].is_a? String
      t = options[nature]
    end
    return t
  end
  

end





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



















