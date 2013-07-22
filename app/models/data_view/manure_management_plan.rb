class DataView::ManureManagementPlan < DataView


  def to_xml(p_campaign)
      #
      builder = Nokogiri::XML::Builder.new  do |xml|#(:target=>$stdout, :indent=>2)
      #xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
      #xml.declare! :DOCTYPE, :html, :PUBLIC, "-//W3C//DTD XHTML 1.0 Strict//EN",
      #"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
      campaign = Campaign.find_by_id(p_campaign.id)
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
    return builder.to_xml
  end

end
