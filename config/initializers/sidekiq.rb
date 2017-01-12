connection = { url: ENV['REDIS_URL'] || "redis://localhost:6379/#{ENV['REDIS_DATABASE_NUMBER'] || 0}" }
connection[:namespace] = ENV['REDIS_NAMESPACE'] if ENV['REDIS_NAMESPACE']

Sidekiq.configure_server do |config|
  config.redis = connection
  schedule_file = Rails.root.join('config', 'schedule.yml')
  if schedule_file.exist?
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end
end

Sidekiq.configure_client do |config|
  config.redis = connection
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs, max_retries: 0
  end
end
