connection = { url: ENV['REDIS_URL'] || "redis://localhost:6379/#{ENV['REDIS_DATABASE_NUMBER'] || 0}" }
connection[:namespace] = ENV['REDIS_NAMESPACE'] if ENV['REDIS_NAMESPACE']

Sidekiq.configure_server do |config|
  config.redis = connection
end

Sidekiq.configure_client do |config|
  config.redis = connection
end
