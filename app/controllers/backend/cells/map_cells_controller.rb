class Backend::Cells::MapCellsController < Backend::CellsController
  #before_action :load_config

  class CartoDBConnection
    def initialize(account, key)
      @account = account
      @key = key
    end

    def exec(sql)
      puts "[#{@account}] #{sql}"
      puts "[#{@account}] " + Net::HTTP.get(URI.parse("http://#{@account}.cartodb.com/api/v2/sql?q=#{URI.encode(sql)}&api_key=#{@key}"))
    end
  end

  def show
    if params[:campaign_ids]
      @campaigns = Campaign.find(params[:campaign_ids])
    else
      @campaigns = Campaign.currents.last
    end
  end

  def update
    if @config
      conn = CartoDBConnection.new(@config[:account], @config[:key])
      data = []
      ProductionSupport.includes({production: [:activity, :campaign, :variant]}, :storage).find_each do |support|
        line = {
          campaign:   support.production.campaign.name,
          activity:   support.production.activity.name,
          production: support.production.name,
          support:    support.name,
          the_geom:   (support.shape ? support.shape_to_ewkt : nil),
          variant:    support.production.variant.name,
          tool_cost:  support.tool_cost.to_s.to_f.round(2),
          input_cost: support.input_cost.to_s.to_f.round(2),
          time_cost:  support.time_cost.to_s.to_f.round(2),
          nitrogen_balance: support.nitrogen_balance.to_s.to_f.round(2),
          phosphorus_balance: support.phosphorus_balance.to_s.to_f.round(2),
          potassium_balance: support.potassium_balance.to_s.to_f.round(2),
          provisional_nitrogen_input: support.provisional_nitrogen_input.to_s.to_f.round(2)
        }
        data << line
      end
      conn.exec("DELETE FROM costs")
      for line in data
        insert = []
        values = []
        for name, value in line
          insert << name
          values << ActiveRecord::Base.connection.quote(value)
          #if name == :the_geom
          #  values << "ST_Force2D(ST_Transform(SetSRID(" + ActiveRecord::Base.connection.quote(value) + ", 2154), 4326))"
          #else
          #  values << ActiveRecord::Base.connection.quote(value)
          #end
        end
        q = "INSERT INTO costs (" + insert.join(', ') + ") SELECT " + values.join(', ')
        conn.exec(q)
      end

      conn = CartoDBConnection.new(@cooperative_config[:account], @cooperative_config[:key])
      data = []
      company = @cooperative_config[:member]
      activities = Activity.of_families(:vegetal_crops)
      Intervention.includes(:production, :production_support, :issue, :recommender, :activity, :campaign, :storage).of_activities(activities).find_each do |intervention|
        line = {
          company: company,
          campaign:   intervention.campaign.name,
          activity:   intervention.activity.name,
          production: intervention.production.name,
          intervention_recommended: intervention.recommended,
          intervention_recommender_name: (intervention.recommended ? intervention.recommender.name : nil),
          intervention_name:    intervention.name,
          intervention_start_time:    intervention.start_time,
          intervention_duration:    intervention.duration.to_s.to_f.round(2),
          the_geom:   (intervention.storage.shape ? intervention.storage.shape_to_ewkt : nil),
          tool_cost:  intervention.cost(:tool).to_s.to_f.round(2),
          input_cost: intervention.cost(:input).to_s.to_f.round(2),
          time_cost:  intervention.cost(:doer).to_s.to_f.round(2)
        }
        data << line
      end
      conn.exec("DELETE FROM interventions WHERE company='#{company}'")
      for line in data
        insert = []
        values = []
        for name, value in line
          insert << name
          values << ActiveRecord::Base.connection.quote(value)
        end
        q = "INSERT INTO interventions (" + insert.join(', ') + ") SELECT " + values.join(', ')
        conn.exec(q)
      end

      data = []
      ProductionSupport.includes({production: [:activity, :campaign, :variant]}, :storage).find_each do |support|
        line = {
          company: company,
          campaign:   support.production.campaign.name,
          activity:   support.production.activity.name,
          production: support.production.name,
          support:    support.name,
          the_geom:   (support.shape ? support.shape_to_ewkt : nil),
          variant:    support.production.variant.name,
          tool_cost:  support.tool_cost.to_s.to_f.round(2),
          input_cost: support.input_cost.to_s.to_f.round(2),
          time_cost:  support.time_cost.to_s.to_f.round(2),
          implanted_at: support.implanted_at,
          harvested_at: support.harvested_at,
          grains_yield: support.grains_yield.to_s.to_f.round(2),
          nitrogen_balance: support.nitrogen_balance.to_s.to_f.round(2),
          phosphorus_balance: support.phosphorus_balance.to_s.to_f.round(2),
          potassium_balance: support.potassium_balance.to_s.to_f.round(2),
          provisional_nitrogen_input: support.provisional_nitrogen_input.to_s.to_f.round(2)
        }
        data << line
      end
      conn.exec("DELETE FROM supports")
      for line in data
        insert = []
        values = []
        for name, value in line
          insert << name
          values << ActiveRecord::Base.connection.quote(value)
        end
        q = "INSERT INTO supports (" + insert.join(', ') + ") SELECT " + values.join(', ')
        conn.exec(q)
      end

    end
    render(:show, visualization: (params[:visualization] || :default))
  end


  protected

  def load_config
    api_file = Rails.root.join("config", "api.yml")
    if api_file.exist?
      config = YAML.load_file(api_file).deep_symbolize_keys
      @config = config[:cartodb]
      @account = @config[:account]
      @visualization = (@config[:visualizations] || {})[(params[:visualization] || :default).to_sym]
      @cooperative_config = config[:cooperative_cartodb]
      @cooperative_config[:member] = @config[:account]
    elsif cartodb_api_key = Identifier.find_by_nature(:cartodb_api_key) and cartodb_subdomain = Identifier.find_by_nature(:cartodb_subdomain)
      # config for self account
      ## Identifier.find_by_nature(:cartodb_subdomain)
      if cartodb_visualization_default = Identifier.find_by_nature(:cartodb_visualization_default) and cartodb_visualization_nitrogen_footprint = Identifier.find_by_nature(:cartodb_visualization_nitrogen_footprint)
        @config = {account: cartodb_subdomain.value, key: cartodb_api_key.value, visualizations:{default: cartodb_visualization_default.value, nitrogen_footprint: cartodb_visualization_nitrogen_footprint.value}}
      @account = @config[:account]
      @visualization = (@config[:visualizations] || {})[(params[:visualization] || :default).to_sym]  
      end
      if cooperative_cartodb_account = Identifier.find_by_nature(:cooperative_cartodb_account) and cooperative_cartodb_key = Identifier.find_by_nature(:cooperative_cartodb_key)
        @cooperative_config = {account: cooperative_cartodb_account.value, key: cooperative_cartodb_key.value}
        @cooperative_config[:member] = @config[:account]
      end
    end
  end

end
