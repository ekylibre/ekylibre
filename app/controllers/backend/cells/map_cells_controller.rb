class Backend::Cells::MapCellsController < Backend::CellsController
  before_action :load_config

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
          the_geom:   (support.shape ? support.shape_as_ewkt : nil),
          variant:    support.production.variant.name,
          tool_cost:  support.tool_cost,
          input_cost: support.input_cost,
          time_cost:  support.time_cost,
          nitrogen_balance: support.nitrogen_balance,
          provisional_nitrogen_input: support.provisional_nitrogen_input
        }
        data << line
      end
      conn.exec("DELETE FROM costs")
      for line in data
        insert = []
        values = []
        for name, value in line
          insert << name
          if name == :the_geom
            values << "ST_Force2D(ST_Transform(SetSRID(" + ActiveRecord::Base.connection.quote(value) + ", 2154), 4326))"
          else
            values << ActiveRecord::Base.connection.quote(value)
          end
        end
        q = "INSERT INTO costs (" + insert.join(', ') + ") SELECT " + values.join(', ')
        conn.exec(q)
      end

      conn = CartoDBConnection.new(@cooperative_config[:account], @cooperative_config[:key])
      data = []
      company = @cooperative_config[:member]
      activities = Activity.where(family: :vine_wine)
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
          intervention_duration:    intervention.duration,
          the_geom:   (intervention.storage.shape ? intervention.storage.shape_as_ewkt : nil),
          tool_cost:  intervention.cost(:tool),
          input_cost: intervention.cost(:input),
          time_cost:  intervention.cost(:doer)
        }
        data << line
      end
      conn.exec("DELETE FROM interventions WHERE company='#{company}'")
      for line in data
        insert = []
        values = []
        for name, value in line
          insert << name
          if name == :the_geom
            values << "ST_Force2D(ST_Transform(SetSRID(" + ActiveRecord::Base.connection.quote(value) + ", 2154), 4326))"
          else
            values << ActiveRecord::Base.connection.quote(value)
          end
        end
        q = "INSERT INTO interventions (" + insert.join(', ') + ") SELECT " + values.join(', ')
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
    end
  end

end
