Sidekiq.configure_server do |config|
  url = ENV['REDIS_URL'] || "redis://localhost:6379/#{ENV['REDIS_DATABASE_NUMBER'] || 0}"
  ns = ENV['REDIS_NAMESPACE'] || '<APPLIANCE>'
  h = { url: url }
  h.merge!(namespace: ns) unless ns.empty?
  config.redis = h
end

Sidekiq.configure_client do |config|
  url = ENV['REDIS_URL'] || "redis://localhost:6379/#{ENV['REDIS_DATABASE_NUMBER'] || 0}"
  ns = ENV['REDIS_NAMESPACE'] || '<APPLIANCE>'
  h = { url: url }
  h.merge!(namespace: ns) unless ns.empty?
  config.redis = h
end