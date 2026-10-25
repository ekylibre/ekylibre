module Admin
  # Holds Redis key constants and status accessors used by both
  # the controller (status polling) and the rake task (admin:tenant:create).
  class CreateTenantJob < ApplicationJob
    REDIS_KEY = 'ekylibre:admin:create_tenant'.freeze

    def self.current_status
      Sidekiq.redis do |r|
        result = r.hgetall(REDIS_KEY)
        {
          status:  result['status']  || 'idle',
          message: result['message'] || '',
          tenant:  result['tenant']  || ''
        }
      end
    end

    def self.reset!
      Sidekiq.redis { |r| r.del(REDIS_KEY) }
    end
  end
end
