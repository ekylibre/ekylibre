class AddThunderforestApiKeyToMapLayers < ActiveRecord::Migration[4.2]
  def up
    return unless api_key = ENV['THUNDERFOREST_API_KEY']
    execute <<-SQL
      UPDATE map_layers
         SET url = url || '?apikey=#{api_key}'
       WHERE url ~ '^https://\{s\}\.tile\.thunderforest.com/[^?]*\.png$'
    SQL
  end

  def down
    #NOOP
  end
end
