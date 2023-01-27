module JobStatus
  extend ActiveSupport::Concern

  included do
    after_enqueue do
      update_status('enqueued')
    end

    after_perform do
      update_status('over')
    end

    rescue_from StandardError, with: :update_status_on_error

    def update_status_on_error(e)
      update_status('over')
      raise if e.present?
    end

    def update_status(status)

      job_name = self.class.to_s
      user = self.arguments.first.fetch(:user)
      raise ArgumentError.new('User key argument must be defined') if user.nil?

      PerformJobButtonsChannel.broadcast_to(user, job: job_name, status: status)
      if status == 'over'
        Preference.find_by(name: "#{job_name}_running").destroy
      else
        Preference.set!("#{job_name}_running", true, :boolean)
      end
    end
  end
end
