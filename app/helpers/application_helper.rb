# -*- coding: utf-8 -*-
# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
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
             {:name=>:custom_fields},
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
             {:name=>:account_reconciliation},
             {:name=>:bookkeep},
             {:name=>:financial_year_close}
           ] },
         {:name=>:documents, :list=>
           [ {:name=>:document_print},
             {:name=>:balance},
             {:name=>:general_ledger}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:accounts},
             {:name=>:financial_years}
           ] }
       ] },
     # FinancesController
     {:name=>:finances, :list=>
       [ {:name=>:financial_operations, :list=>
           [ {:name=>:incoming_payments},
             {:name=>:outgoing_payments},
             {:name=>:deposits},
             # {:name=>:tax_declarations},
             {:name=>:cash_transfers}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:cashes},
             {:name=>:taxes},
             {:name=>:incoming_payment_modes},
             {:name=>:outgoing_payment_modes}
           ] }
       ] },
     # ManagementController
     {:name=>:management, :list=>
       [ {:name=>:sales, :list=>
           [ {:name=>:sale_create},
             {:name=>:sales},
             {:name=>:subscriptions},
             {:name=>:statistics}
           ] },
         {:name=>:purchases, :list=>
           [ {:name=>:purchase_create},
             {:name=>:purchases},
           ] },
         {:name=>:stocks_tasks, :list=>
           [{:name=>:stocks},
            {:name=>:outgoing_deliveries},
            {:name=>:incoming_deliveries},  
            {:name=>:transports},
            {:name=>:warehouses},
            {:name=>:stock_transfers},
            {:name=>:inventories}  
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:products},
             {:name=>:prices},
             {:name=>:product_categories},
             {:name=>:delays},
             {:name=>:incoming_delivery_modes},
             {:name=>:outgoing_delivery_modes},
             {:name=>:sale_natures},
             {:name=>:subscription_natures}
           ] }
       ] },


     # ProductionController
     {:name=>:production, :list=>
       [ {:name=>:production, :list=>
           [ {:name=>:land_parcels},
             # {:name=>:production_chains},
             {:name=>:operations}
           ] },
         {:name=>:parameters, :list=>
           [ {:name=>:tools},
             {:name=>:land_parcel_groups},
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

  def number_to_management(value)
    number = value.to_f
    number_to_currency(number, :precision=>2, :format=>'%n', :delimiter=>'&nbsp;', :separator=>',')
  end


  def preference(name)
    # name = self.controller.controller_name.to_s+name.to_s if name.to_s.match(/^\./)
    @current_company.preference(name)
  end

  def locale_selector
    # , :selected=>::I18n.locale)
    locales = ::I18n.active_locales.sort{|a,b| a.to_s<=>b.to_s}
    locale = nil # ::I18n.locale
    if params[:locale].to_s.match(/^[a-z][a-z][a-z]$/)
      locale = params[:locale].to_sym if locales.include? params[:locale].to_sym
    end
    locale ||= ::I18n.locale||::I18n.default_locale
    options = locales.collect do |l|
      content_tag(:option, ::I18n.translate("i18n.name", :locale=>l), {:value=>l, :dir=>::I18n.translate("i18n.dir", :locale=>l)}.merge(locale == l ? {:selected=>true} : {}))
    end.join.html_safe
    select_tag("locale", options, :onchange=>"window.location.replace('#{url_for(:locale=>'LOCALE').gsub('LOCALE', '\'+this.value+\'')}')") # "remote_function(:url=>request.url, :with=>"'locale='+this.value")")
  end

  def svg_test_tag
    return '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full"><g fill-opacity="0.7" stroke="black" stroke-width="0.1cm"><circle cx="6cm" cy="2cm" r="100" fill="red" transform="translate(0,50)" /><circle cx="6cm" cy="2cm" r="100" fill="blue" transform="translate(70,150)" /><circle cx="6cm" cy="2cm" r="100" fill="green" transform="translate(-70,150)" /></g></svg>'.html_safe
  end

  if Rails.version.match(/^2\.3/)

    # Rails 2.3 helpers
    def link_to(*args, &block)
      if block_given?
        options      = args.first || {}
        html_options = args.second
        # concat(link_to(capture(&block), options, html_options))
        link_to(capture(&block), options, html_options)
      else
        name         = args.first
        options      = args.second || {}
        html_options = args.third || {}

        if options.is_a? Hash
          return (html_options[:keep] ? "<a class='forbidden'>#{name}</a>" : "") unless controller.accessible?(options) 
        end

        [:confirm, :method, :remote].each{|x| html_options["data-#{x}"] = html_options.delete(x) if html_options[x] }
        [:confirm, :method, :remote].each{|x| html_options["data-#{x}"] = options[x] if options[x] } if options.is_a? Hash
        url = url_for(options)

        if html_options
          html_options = html_options.stringify_keys
          href = html_options['href']
          # convert_options_to_javascript!(html_options, url)
          tag_options = tag_options(html_options)
        else
          tag_options = nil
        end
        
        href_attr = "href=\"#{url}\"" unless href
        "<a #{href_attr}#{tag_options}>#{name || url}</a>"
      end
    end

    module ::ActionView::Helpers::FormTagHelper
      def form_tag_in_block_with_compat(html_options, &block)
        content = capture(&block)
        return form_tag_html(html_options).html_safe+content.html_safe+"</form>".html_safe
      end
      alias_method_chain :form_tag_in_block, :compat

      def form_tag_with_compat(url_for_options = {}, options = {}, *parameters_for_url, &block)
        html_options = html_options_for_form(url_for_options, options, *parameters_for_url)
        if block_given?
          form_tag_in_block(html_options, &block)
        else
          form_tag_html(html_options)
        end
      end
      alias_method_chain :form_tag, :compat
    end

#     def keishiki_tag(url_for_options = {}, options = {}, *parameters_for_url, &block)
#       return form_tag(url_for_options, options, *parameters_for_url, &block)
#     end

  else
    # Rails 3 helpers
    def link_to(*args, &block)
      if block_given?
        options      = args.first || {}
        html_options = args.second
        link_to(capture(&block), options, html_options)
      else
        name         = args[0]
        options      = args[1] || {}
        html_options = args[2] || {}

        if options.is_a? Hash
          return (html_options[:keep] ? "<a class='forbidden'>#{name}</a>".html_safe : "") unless controller.accessible?(options) 
        end
        
        html_options = convert_options_to_data_attributes(options, html_options)
        url = url_for(options)
        
        if html_options
          html_options = html_options.stringify_keys
          href = html_options['href']
          tag_options = tag_options(html_options)
        else
          tag_options = nil
        end
        
        href_attr = "href=\"#{html_escape(url)}\"" unless href
        "<a #{href_attr}#{tag_options}>#{html_escape(name || url)}</a>".html_safe
      end
    end


#     def keishiki_tag(url_for_options = {}, options = {}, *parameters_for_url, &block)
#       return form_tag(url_for_options, options, *parameters_for_url, &block)
#     end

  end
  def li_link_to(*args)
    options      = args[1] || {}
    if controller.accessible?({:controller=>controller_name, :action=>action_name}.merge(options))
      content_tag(:li, link_to(*args).html_safe)
    else
      ''
    end
  end
  
  def countries
    [[]]+t('countries').to_a.sort{|a, b| a[1].ascii.to_s<=>b[1].ascii.to_s}.collect{|a| [a[1].to_s, a[0].to_s]}
  end

  def languages
    I18n.valid_locales.collect{|l| [t("languages.#{l}"), l.to_s]}.to_a.sort{|a, b| a[0].ascii.to_s<=>b[0].ascii.to_s}
  end

  def link_to_back(options={})
    #    link_to tg(options[:label]||'back'), :back
    link_to tg(options[:label]||'back'), session[:history][1]
  end
  #


  def attribute_item(object, attribute, options={})
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
      default << "attributes.#{attribute.to_s}".to_sym
      default << "attributes.#{attribute.to_s}_id".to_sym
      label = ::I18n.translate("activerecord.attributes.#{object.class.name.underscore}.#{attribute.to_s}".to_sym, :default=>default)
      if value.is_a? ActiveRecord::Base
        record = value
        value = record.send(options[:label]||[:label, :name, :code, :number, :inspect].detect{|x| record.respond_to?(x)})
        options[:url][:id] ||= record.id if options[:url]
      end
      value_class += ' code' if attribute.to_s == "code"
    end
    if [TrueClass, FalseClass].include? value.class
      value = content_tag(:div, "", :class=>"checkbox-#{value}")
    elsif ["Date", "Time", "DateTime"].include? value.class.name
      value = ::I18n.localize(value)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif options[:duration]
      duration = value
      duration = duration*60 if options[:duration]==:minutes
      duration = duration*3600 if options[:duration]==:hours
      hours = (duration/3600).floor.to_i
      minutes = (duration/60-60*hours).floor.to_i
      seconds = (duration - 60*minutes - 3600*hours).round.to_i
      value = tg(:duration_in_hours_and_minutes, :hours=>hours, :minutes=>minutes, :seconds=>seconds)
      value = link_to(value.to_s, options[:url]) if options[:url]
    elsif value.is_a? String
      classes = []
      classes << "code" if attribute.to_s == "code"
      classes << value.class.name.underscore
      value = link_to(value.to_s, options[:url]) if options[:url]
      value = content_tag(:div, value.html_safe, :class=>classes.join(" "))
    end
    return label, value
  end


  #
  def evalue(object, attribute, options={})
    label, value = attribute_item(object, attribute, options={})
    if options[:orient] == :vertical
      code  = content_tag(:tr, content_tag(:td, label.to_s, :class=>:label))
      code += content_tag(:tr, content_tag(:td, value.to_s, :class=>:value))
      return content_tag(:table, code, :class=>"evalue verti")
    else
      code  = content_tag(:td, label.to_s, :class=>:label)
      code += content_tag(:td, value.to_s, :class=>:value)
      return content_tag(:table, content_tag(:tr, code), :class=>"evalue hori")
    end
  end


  def attributes_list(record, options={}, &block)
    columns = options[:columns] || 3
    attribute_list = AttributesList.new
    raise ArgumentError.new("One parameter needed") unless block.arity == 1
    yield attribute_list if block_given?
    unless options[:without_stamp]
      attribute_list.attribute :creator
      attribute_list.attribute :created_at
      attribute_list.attribute :updater
      attribute_list.attribute :updated_at
      # attribute_list.attribute :lock_version
    end
    code = ""
    size = attribute_list.items.size
    if size > 0
      column_height = (size.to_f/columns.to_f).ceil

      column_height.times do |c|
        line = ""
        columns.times do |i|
          args = attribute_list.items[i*column_height+c] # [c*columns+i]
          next if args.nil?
          label, value = if args[0] == :custom
                           attribute_item(*args[1])
                         elsif args[0] == :attribute
                           attribute_item(record, *args[1])
                         end
          line += content_tag(:td, label, :class=>:label)+content_tag(:td, value, :class=>:value)
        end
        code += content_tag(:tr, line.html_safe)
      end
      code = content_tag(:table, code.html_safe, :class=>"attributes-list")

      #       for c in 1..columns
      #         column = ""
      #         for i in 1..column_height
      #           args = attribute_list.items.shift
      #           break if args.nil?
      #           if args[0] == :evalue
      #             column += evalue(*args[1]) if args.is_a? Array
      #           elsif args[0] == :attribute
      #             column += evalue(record, *args[1]) if args.is_a? Array
      #           end
      #         end
      #         code += content_tag(:td, column.html_safe)
      #       end
      #       code = content_tag(:tr, code.html_safe)
      #      code = content_tag(:table, code.html_safe, :class=>"attributes-list")
    end
    return code.html_safe
  end

  class AttributesList
    attr_reader :items
    def initialize()
      @items = []
    end

    def attribute(*args)
      @items << [:attribute, args]
    end

    def custom(*args)
      @items << [:custom, args]
    end

  end    




  #   def sessany
  #     return (@current_company ? session[@current_company.code] ||= {} : session)
  #   end
  
  def last_page(controller)
    session[:last_page][controller]||url_for(:controller=>controller, :action=>:index)
  end


  def doctype_tag
    return "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN\" \"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd\">".html_safe
  end



  # Permits to use themes for Ekylibre
  #  stylesheet_link_tag 'application', 'kame', 'kame-colors'
  #  stylesheet_link_tag 'print', :media=>'print'
  def theme_link_tag(name=nil)
    name ||= 'tekyla'
    code = ""
    for sheet, media in ["screen", "print", "kame", "kame-colors"]
      media = (sheet == "print" ? :print : :screen)
      if File.exists?("#{Rails.root}/public/themes/#{name}/stylesheets/#{sheet}.css")
        code += stylesheet_link_tag("/themes/#{name}/stylesheets/#{sheet}.css", :media=>media)
      end
    end
    return code.html_safe
  end


  def theme_button(name, theme='tekyla')
    Rails.root.join("public", "themes", theme, "images", "buttons", "#{name}.png").to_s
  end


  # <script src="/red/javascripts/calendar/calendar.js" type="text/javascript"></script>
  # <script src="/red/javascripts/calendar/lang/calendar-fr.js" type="text/javascript"></script>
  # <script src="/red/javascripts/calendar/calendar-setup.js" type="text/javascript"></script>
  # , 'calendar/border-radius'
  def calendar_link_tag(lang='fr')
    (javascript_include_tag('calendar/calendar', 'calendar/lang/calendar-'+lang, 'calendar/calendar-setup')+
     stylesheet_link_tag('calendar')).html_safe
  end

  # <p><label for="issue_start_date">Start</label>
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


  def resizable?
    return ((@current_user and @current_user.preference("interface.general.resized", true, :boolean).value) or @current_user.nil?)
  end

  def top_tag
    session[:last_page] ||= {}
    code = ''

    # User Tag
    tag = []
    if @current_user
      preference = @current_user.preference("interface.general.resized", true, :boolean)
      resized = preference.value
      tag << link_to("", params.merge(:resized=>(resized ? "0" : "1")), {:class=>"icon im-#{'un' if resized}printable", :title=>tl(:toggle_print_mode), :id=>:resizable})+" "
      # tag << content_tag(:a, @current_user.label)
      tag << content_tag(:a, @current_user.label)
      tag << content_tag(:a, @current_company.name)
      tag << link_to(t("actions.authentication.logout"), {:controller=>:authentication, :action=>:logout}, :class=>"icon im-logout")
    end
    code += content_tag(:div, tag.join(" ").html_safe, :id=>:user, :class=>:menu)

    code += content_tag(:div, "", :id=>:loading, :style=>'display:none;')

    # Modules Tag
    tag = ''
    for m in MENUS
      if controller.accessible?({:controller=>m[:name]})
        tag += link_to_if(self.controller.controller_name!=m[:name].to_s, t("controllers.#{m[:name]}"), last_page(m[:name].to_s)) do |name|
          link_to(name, {:controller=>m[:name], :action=>:index}, :class=>:current)
        end+" "
      end
    end if @current_user
    
    code += content_tag(:div, tag.html_safe, :id=>:modules, :class=>:menu)
    
    return code.html_safe
  end



  def action_title
    options = @title.is_a?(Hash) ? @title : {}
    return ::I18n.translate("actions.#{controller.controller_name}.#{controller.action_name}", options)
  end

  def title_tag
    title = if @current_company
              tc(:page_title, :company_code=>@current_company.code, :company_name=>@current_company.name, :controller=>t("controllers.#{controller.controller_name}"), :action=>action_title)
            else
              tc(:page_title_by_default, :controller=>t("controllers.#{controller.controller_name}"), :action=>action_title)
            end
    return content_tag(:title, title)
  end

  def title_header_tag
    titles = action_title
    content_tag(:h1, titles, :class=>"title", :title=>titles)
  end

  def help_link_tag(options={})
    return '' if @current_user.blank?
    options[:class] ||= ""
    options[:class] += " icon im-help help-link"
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
    return code.html_safe
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
    code.html_safe
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
    content.gsub!(/(\w+)[\ \~]+(\?|\:)/ , '\1~\2' )
    content.gsub!(/\~/ , '&#160;')

    content.gsub!(/^\ \ \*\ +(.*)\ *$/ , '<ul><li>\1</li></ul>')
    content.gsub!(/<\/ul>\n<ul>/ , '')
    content.gsub!(/^\ \ \-\ +(.*)\ *$/ , '<ol><li>\1</li></ol>')
    content.gsub!(/<\/ol>\n<ol>/ , '')
    content.gsub!(/^\ \ \?\ +(.*)\ *$/ , '<dl><dt>\1</dt></dl>')
    content.gsub!(/^\ \ \!\ +(.*)\ *$/ , '<dl><dd>\1</dd></dl>')
    content.gsub!(/<\/dl>\n<dl>/ , '')

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
        src = File.join(Rails.public_path, "themes", @current_theme, "images", src.split(':')[1])
      else
        src = File.join(Rails.public_path, "images", src)
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
      link_to_remote(link[1].html_safe, options) # REMOTE
    end

    content = content.gsub(/\[\[[\w\-]+\]\]/) do |link|
      link = link[2..-3]
      options[:url][:article] = link
      link_to_remote(link.html_safe, options) # REMOTE
    end

    for x in 1..6
      n = 7-x
      content.gsub!(/^\s*\={#{n}}\s*([^\=]+)\s*\={#{n}}/, "<h#{x}>\\1</h#{x}>")
    end

    content.gsub!(/^\ \ (.*\w+.*)$/, '  <pre>\1</pre>')

    content.gsub!(/([^\:])\/\/([^\s][^\/]+)\/\//, '\1<em>\2</em>')
    content.gsub!(/\'\'([^\s][^\']+)\'\'/, '<code>\1</code>')
    content.gsub!(/(^)([^\s\<][^\s].*)($)/, '<p>\2</p>') unless options[:without_paragraph]
    content.gsub!(/^\s*(\<a.*)\s*$/, '<p>\1</p>')

    content.gsub!(/\*\*([^\s\*]+)\*\*/, '<strong>\1</strong>')
    content.gsub!(/\*\*([^\s\*][^\*]*[^\s\*])\*\*/, '<strong>\1</strong>')
    content.gsub!(/(^|[^\*])\*([^\*]|$)/, '\1&lowast;\2')
    content.gsub!("</p>\n<p>", "\n")

    content.strip!

    #raise Exception.new content
    return content.html_safe
  end


  def article(name, options={})
    name = name.to_s
    content = ''
    file_name, locale = '', nil
    for locale in [I18n.locale, I18n.default_locale]
      help_dir = Rails.root.join("config", "locales", locale.to_s, "help")
      file_name = [name, name.gsub(/_[a-z0-9]+$/, '').pluralize, name.pluralize].detect do |pattern|
        File.exists? help_dir.join(pattern+".txt")
      end
      break unless file_name.blank?
    end
    file_text = Rails.root.join("config", "locales", locale.to_s, "help", file_name.to_s+".txt")
    if File.exists?(file_text)
      File.open(file_text, 'r') do |file|
        content = file.read
      end
      content = wikize(content, options)
    end
    return content
  end

  


  # Unagi 鰻 
  # Flexible module management
  def unagi(options={})
    u = Unagi.new
    yield u
    tag = ""
    for c in u.cells
      code = content_tag(:h2, tl(c.title, c.options))+content_tag(:div, capture(&c.block).html_safe)
      tag += content_tag(:div, code.html_safe, :class=>:menu)
    end
    return content_tag(:div, tag.html_safe, :class=>:unagi)
  end

  class Unagi
    attr_reader :cells
    def initialize
      @cells = []
    end
    def cell(title, options={}, &block)
      @cells << UnagiCell.new(title, options, &block)
    end
  end

  class UnagiCell
    attr_reader :title, :options, :block
    def initialize(title, options={}, &block)
      @title = title.to_s
      @options = options
      @block = block
    end

    def content
      "aAAAAAAAAAAAAAAAAAA"+capture(@block).to_s
    end
  end


  # Kujaku 孔雀
  # Search bar
  def kujaku(options={})
    k = Kujaku.new
    yield k
    tag = ""
    first = true
    for c in k.criteria
      if c[0] == :mode
        code = content_tag(:label, tg(:modes))
        name = options[:name]||:mode
        params[name] ||= c[1][0].to_s
        for mode in c[1]
          radio  = radio_button_tag(name, mode, params[name] == mode.to_s)
          radio += " "
          radio += content_tag(:label, tl("criterion_modes.#{mode}"), :for=>"#{name}_#{mode}")
          code += " ".html_safe+content_tag(:span, radio.html_safe, :class=>:rad)
        end
      end
      code = content_tag(:td, code.html_safe, :class=>:crit) 
      if first
        code += content_tag(:td, submit_tag(tl(:search_go), :disable_with=>tg(:please_wait)), :rowspan=>k.criteria.size, :class=>:submit)
        first = false
      end
      tag += content_tag(:tr, code.html_safe)
    end
    tag = form_tag({}, :method=>:get) {content_tag(:table, tag.html_safe)}
    return content_tag(:div, tag.to_s.html_safe, :class=>:kujaku)
  end

  class Kujaku
    attr_reader :criteria
    def initialize
      @criteria = []
    end
    def mode(modes, options={})
      @criteria << [:mode, modes, options]
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
      tablabels += link_to_function((tab[:name].is_a?(Symbol) ? tl("#{tb.id}_tabbox.#{tab[:name]}") : tab[:name]), "#{jsmethod}(#{tab[:index]})", :class=>:tab, :id=>tab[:id]+tl)
      tabpanels += content_tag(:div, capture(&tab[:block]).html_safe, :class=>:tabpanel, :id=>tab[:id]+tp)
    end
    js += "$('#{tb.prefix}'+index+'#{tp}').addClassName('current');"
    js += "$('#{tb.prefix}'+index+'#{tl}').addClassName('current');"
    js += "new Ajax.Request('#{url_for(:controller=>:company, :action=>:tabbox_index, :id=>tb.id)}?index='+index);"
    js += "return true;};"
    js += "#{jsmethod}(#{(session[:tabbox] ? session[:tabbox][tb.id] : nil)||tabs[0][:index]});"
    code  = content_tag(:div, tablabels.html_safe, :class=>:tabs)+content_tag(:div, tabpanels.html_safe, :class=>:tabpanels)
    code += javascript_tag(js)
    content_tag(:div, code.html_safe, :class=>options[:class]||"tabbox", :id=>tb.id)
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

    def tab(name, options={}, &block)
      raise ArgumentError.new("No given block") unless block_given?
      @sequence += 1
      @tabs << {:name=>name, :index=>@sequence, :id=>@id+@separator+@sequence.to_s, :block=>block}
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
      # call = 'views.'+caller.detect{|x| x.match(/\/app\/views\//)}.split(/\/app\/views\//)[1].split('.')[0].gsub(/\//,'.')+'.'
      for tool in toolbar.tools
        nature, args = tool[0], tool[1]
        if nature == :link
          name = args[0]
          args[1] ||= {}
          args[2] ||= {}
          args[2][:class] ||= "icon im-"+name.to_s.split('_')[-1]
          if args[1].is_a? Hash and args[1][:remote]
            args[1].delete(:remote)
            args[1][:url] ||= {}
            if name.is_a? Symbol
              args[1][:url][:action] ||= name
              # args[0] = ::I18n.t("#{call}#{name}".to_sym, :default=>["actions.#{args[1][:url][:controller]||controller_name}.#{name}".to_sym]) 
              args[0] = ::I18n.t("labels.#{name}".to_sym, :default=>["actions.#{args[1][:url][:controller]||controller_name}.#{name}".to_sym]) 
            end
            if controller.accessible?({:controller=>controller_name, :action=>action_name}.merge(args[1][:url]))
              code += content_tag(:li, link_to_remote(*args).html_safe)
            end
          else
            # args[0] = ::I18n.t("#{call}#{name}".to_sym, :default=>["actions.#{args[1][:controller]||controller_name}.#{name}".to_sym]) if name.is_a? Symbol
            args[0] = ::I18n.t("labels.#{name}".to_sym, :default=>["actions.#{args[1][:controller]||controller_name}.#{name}".to_sym]) if name.is_a? Symbol
            if name.is_a? Symbol and name!=:back
              args[1][:action] ||= name
            else
              args[2][:class] = "icon im-"+args[1][:action].to_s.split('_')[-1] if args[1][:action]
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
          args[2][:class] = "icon im-print"
          #          raise Exception.new "ok"+args.inspect
          for dc in @current_company.document_templates.find_all_by_nature_and_active(name, true)
            args[0] = tc(:print_with_template, :name=>dc.name)
            args[1][:id] = dc.code
            #raise Exception.new "ok"
            code += li_link_to(*args)
          end
        elsif nature == :javascript
          name = args[0]
          # args[0] = ::I18n.t("#{call}#{name}".to_sym) if name.is_a? Symbol
          args[0] = tl(name) if name.is_a? Symbol
          args[2] ||= {}
          args[2][:class] ||= "icon im-"+name.to_s.split('_')[-1]
          code += content_tag(:li, link_to_function(*args).to_s)
        elsif nature == :mail
          args[2] ||= {}
          args[2][:class] = "icon im-mail"
          code += content_tag(:li, mail_to(*args).to_s)
        elsif nature == :update
          action = args.class.name.underscore+"_update"
          url_options = {} unless url_options.is_a? Hash
          url_options[:action] = action
          url_options[:id] = args.id
          code += content_tag(:li, link_to(t("actions.#{url_options[:controller]||controller_name}.#{action}", args.attributes.symbolize_keys), url_options, {:class=>"icon im-update"})) if not record.respond_to?(:updateable?) or (record.respond_to?(:updateable?) and record.updateable?)
        elsif nature == :missing
          verb, record, tag_options = tool[1], tool[2], tool[3]
          action = "#{record.class.name.underscore}_#{verb}"
          tag_options = {} unless tag_options.is_a? Hash
          tag_options[:class] = "icon im-#{verb}"
          url_options = {} unless url_options.is_a? Hash
          url_options.merge(tag_options.delete(:params)) if tag_options[:params].is_a? Hash
          url_options[:action] = action
          url_options[:id] = record.id
          code += content_tag(:li, link_to(t("actions.#{url_options[:controller]||controller_name}.#{action}", record.attributes.symbolize_keys), url_options, tag_options))
        end
      end
      if code.strip.length>0
        code = content_tag(:ul, code.html_safe)+content_tag(:div)
        code = content_tag(:h2, t(call+options[:title].to_s))+code if options[:title]
        code = content_tag(:div, code.html_safe, :class=>'toolbar'+(options[:class].nil? ? '' : ' '+options[:class].to_s))
      end
    else
      raise Exception.new('No block given for toolbar')
    end
    return code.html_safe
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

    #     def update(record, url_options={})
    #       @tools << [:update, record, url_options]
    #     end

    def method_missing(method_name, *args, &block)
      raise ArgumentError.new("Block can not be accepted") if block_given?
      raise ArgumentError.new("First argument must be an ActiveRecord::Base") unless args[0].class.ancestors.include? ActiveRecord::Base
      @tools << [:missing, method_name, args[0], args[1]]
    end
  end


  def error_messages(object)
    object = instance_variable_get("@#{object}") unless object.respond_to?(:errors)
    return unless object.respond_to?(:errors)
    unless (count = object.errors.size).zero?
      I18n.with_options :scope => [:errors, :template] do |locale|
        header_message = locale.t :header, :count => count, :model => object.class.model_name.human
        introduction = locale.t(:body)
        messages = object.errors.full_messages.map do |msg|
          content_tag(:li, msg)
        end.join.html_safe
        contents = ''
        contents << content_tag(:h3, header_message) unless header_message.blank?
        contents << content_tag(:p, introduction) unless introduction.blank?
        contents << content_tag(:ul, messages)
        content_tag(:div, contents.html_safe, :class=>"flash error")
      end
    else
      ''
    end
  end




  class Formalize
    attr_reader :lines

    def initialize()
      @lines = []
    end

    def title(value=:general_informations, options={})
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

    # def error(*params)
    def error(object)
      @lines << {:nature=>:error, :object=>object}
    end
  end


  def formalize(options={})
    code = if block_given?
             form = Formalize.new
             yield form
             formalize_lines(form, options)
           else
             '[EmptyFormalizeError]'
           end
    return code.html_safe
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
        line_code += content_tag(:td, error_messages(line[:object]), :class=>"error", :colspan=>xcn)
      when :title
        if line[:value].is_a? Symbol
          #calls = caller
          #file = calls[3].split(/\:\d+\:/)[0].split('/')[-1].split('.')[0]
          options = line.dup
          options.delete_if{|k,v| [:nature, :value].include?(k)}
          line[:value] = tl(line[:value], options)
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
        code += content_tag(:tr, line_code.html_safe, html_options)
      end
      
    end
    code = content_tag(:table, code.html_safe, :class=>'formalize',:id=>form_options[:id])
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
      raise Exception.new('ModelError on object (not an ActiveRecord): '+object.class.to_s) unless model.ancestors.include? ActiveRecord::Base # methods.include? "create"

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
                options[:choices].collect{|x| content_tag(:span, radio_button(record, method, x[1])+" "+content_tag(:label, x[0], :for=>input_id+'_'+x[1].to_s), :class=>:rad)}.join(" ").html_safe
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
          data = if options[:remote]
                   options[:remote]
                 elsif options[:field] == :dyselect
                   "refreshList('#{rlid}', request, '#{url_for(options[:choices].merge(:controller=>:company, :action=>:formalize))}');"
                 else
                   "refreshAutoList('#{rlid}', request);"
                 end
          data = ActiveSupport::Base64.encode64(Marshal.dump(data))
          input += link_to_function(label, "openDialog('#{url_for(options[:new].merge(:formalize=>data))}')", :href=>url_for(options[:new]), :class=>:fastadd)
        end
      end
      
      label = object.class.human_attribute_name(method.to_s)
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
                  options[:choices].collect{ |x| content_tag(:span, radio_button_tag(name, x[1], (value.to_s==x[1].to_s), :id=>"#{name}_#{x[1]}")+" "+content_tag(:label,x[0], :for=>"#{name}_#{x[1]}"), :class=>:rad) }.join(" ").html_safe
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
                  select_tag(name, options_for_select([""]+choices, (value.is_a?(ActiveRecord::Base) ? value.id : value)), :id=>options[:id])
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



















