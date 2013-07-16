# -*- coding: utf-8 -*-
class Backend::ProductionsController < BackendController

  manage_restfully(:t3e => {:name => 'RECORD.name'})

  unroll_all


  # management -> sales_conditions
  def self.productions_conditions
    code = ""
    code = search_conditions(:production, :productions => [:state], :activities =>[:name], :product_natures =>[:name]) + "||=[]\n"
    code << "unless session[:production_state].blank?\n"
    code << "  if session[:production_state] == 'all'\n"
    code << "    c[0] += \" AND state IN ('draft', 'validated', 'aborted', 'started')\"\n"
    code << "  end\n "
    code << "  if session[:production_campaign_id] > 0\n"
    code << "    c[0] += \" AND \#{Campaign.table_name}.id = ?\"\n"
    code << "    c << session[:production_campaign_id]\n"
    code << "  end\n"
    code << "  if session[:production_state].present? and session[:production_state] != 'all'\n"
    code << "    c[0] += \" AND state = ?\"\n"
    code << "    c << session[:production_state]\n"
    code << "  end\n"
    code << "  if session[:production_product_nature_id] > 0\n"
    code << "    c[0] += \" AND \#{ProductNature.table_name}.id = ?\"\n"
    code << "    c << session[:production_product_nature_id]\n"
    code << "  end\n"
    code << "end\n "
    code << "c\n "
    code
  end



  list(:conditions => productions_conditions, :joins => [:activity,:product_nature,:campaign]) do |t|
    t.column :name, :url => true
    t.column :name,:through => :activity, :url => true
    #t.column :name,:through => :campaign, :url => true
    #t.column :name,:through => :product_nature, :url => true
    t.column :state_label
    t.action :edit, :if => 'RECORD.draft? '
    #t.action :print, :if => 'RECORD.validated? '
    t.action :destroy, :if => 'RECORD.aborted? '

  end

  # Displays the main page with the list of productions.
  def index
    session[:production_state] = params[:s] ||="all"
    session[:production_key] = params[:q]
    session[:production_product_nature_id] = params[:product_nature_id].to_i
    session[:production_campaign_id] = params[:campaign_id].to_i
    respond_to do |format|
      format.html
      format.xml  { render :xml => Production.all }
      format.json { render :json => Production.all }
    end
  end

  # Displays the page for one production.
  def show
    return unless @production = find_and_check
    respond_to do |format|
      format.html { t3e(@production, :name => @production.name) }
      format.xml  { render :xml => @production }
      format.json { render :json => @production }
    end
  end

   def fertilization
      #
      builder = Nokogiri::XML::Builder.new  do |xml|#(:target=>$stdout, :indent=>2)
      #xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
      #xml.declare! :DOCTYPE, :html, :PUBLIC, "-//W3C//DTD XHTML 1.0 Strict//EN",
      #"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
      campaign = Campaign.first
      entity = Entity.of_company
      groups = LandParcelGroup.where("type <> 'LandParcelCluster'")#of_campaign(campaigns)
      #raise groups.inspect
      xml.land_parcel_groups(:campaign => campaign.name, :entity_name => entity.full_name) do
        for group in groups
          xml.land_parcel_group(:id => group.id,
                                :work_number => group.work_number,
                                :name => group.name,
                                :area => group.area_measure.value,
                                :area_unit => group.area_measure.measure_unit,
                                :svg_path => group.shape_path
                                ) do
            for production in group.productions.of_campaign(campaign)
              xml.production(:name => production.name ) do
                # need to get only thr procedures with the procedurevariable with one or most target = land_parcel_group
                for procedure in production.procedures.real.of_natures("soil_enrichment").with_variable("target", group) #and production.variables.where(:target_id => group.id))
                  xml.fertilization_real(:started_at => procedure.started_at, :stopped_at => procedure.stopped_at) do
                    for input_variable in procedure.variables.of_role(:input)
                    xml.input(:input => input_variable.target.name,
                              :input_nature => input_variable.target.nature.name,
                              :input_variety => input_variable.target.variety,
                              :input_quantity => input_variable.measure_quantity,
                              :input_quantity_unit => input_variable.measure_unit,
                              :started_at => procedure.started_at,
                              :stopped_at => procedure.stopped_at,
                              :input_nitrogen_concentration => input_variable.target.indicator_data.where(:indicator => "nitrogen_concentration").last.value,
                              :input_phosphorus_concentration => input_variable.target.indicator_data.where(:indicator => "phosphorus_concentration").last.value,
                              :input_potassium_concentration => input_variable.target.indicator_data.where(:indicator => "potassium_concentration").last.value
                              )
                    end
                  end
                end
                for procedure in production.procedures.provisional.of_natures("soil_enrichment").with_variable("target", group)
                  xml.fertilization_prev(:started_at => procedure.started_at, :stopped_at => procedure.stopped_at) do
                    for input_variable in procedure.variables.of_role(:input)
                    xml.input(:input => input_variable.target.name,
                              :input_nature => input_variable.target.nature.name,
                              :input_variety => input_variable.target.variety,
                              :input_quantity => input_variable.measure_quantity,
                              :input_quantity_unit => input_variable.measure_unit,
                              :started_at => procedure.started_at,
                              :stopped_at => procedure.stopped_at,
                              :input_nitrogen_concentration => input_variable.target.indicator_data.where(:indicator => "nitrogen_concentration").last.value,
                              :input_phosphorus_concentration => input_variable.target.indicator_data.where(:indicator => "phosphorus_concentration").last.value,
                              :input_potassium_concentration => input_variable.target.indicator_data.where(:indicator => "potassium_concentration").last.value
                              )
                    end
                  end
                end
              end
            end
          end
        end
      end
      end
      @fertilization = builder.to_xml
      respond_to do |format|
        format.xml { render :text => @fertilization}
      end
  end

end
