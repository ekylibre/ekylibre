class Backend::Cells::MapCellsController < Backend::CellsController
  before_action :load_config

  def show
  end

  def update
    if @map
      cexec = Proc.new { |sql|
        puts sql
        puts Net::HTTP.get(URI.parse("http://#{@map[:account]}.cartodb.com/api/v2/sql?q=#{URI.encode(sql)}&api_key=#{@map[:key]}"))
      }
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
          nitrogen_balance: support.nitrogen_balance
        }
        data << line
      end
      cexec["DELETE FROM costs"]
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
        cexec[q]
      end
      render(:show, visualization: (params[:visualization] || :default))
    end
  end

  protected

  def load_config
    api_file = Rails.root.join("config", "api.yml")
    if api_file.exist?
      @map = YAML.load_file(api_file).deep_symbolize_keys[:cartodb]
      @account = @map[:account]
      @visualization = (@map[:visualizations] || {})[(params[:visualization] || :default).to_sym]
    end
  end

end
