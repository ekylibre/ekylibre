class Admin::LexiconController < Admin::BaseController
  REDIS_KEY = 'ekylibre:admin:lexicon'.freeze
  VERSION_FORMAT = /\A[a-zA-Z0-9._\-]+\z/.freeze

  def available
    prefix = params[:prefix].presence
    render json: {
      versions: Ekylibre::Lexicon.available_versions(prefix: prefix),
      credentials_present: minio_credentials_present?
    }
  end

  def download
    return render_busy if running?

    version = params[:version].to_s.strip
    return render_invalid_version unless valid_version?(version)

    reset!
    spawn_task('download', version, "Téléchargement de la version #{version} en cours...")
    render json: { status: 'running', message: "Téléchargement de '#{version}' lancé..." }
  end

  def activate
    return render_busy if running?

    version = params[:version].to_s.strip
    keep    = params[:keep].to_s == 'true'
    return render_invalid_version unless valid_version?(version)

    reset!
    spawn_task('activate', version, "Activation de la version #{version} en cours...", keep: keep)
    render json: { status: 'running', message: "Activation de '#{version}' lancée..." }
  end

  def remove
    return render_busy if running?

    version = params[:version].to_s.strip
    return render_invalid_version unless valid_version?(version)

    reset!
    spawn_task('remove', version, "Suppression de la version #{version} en cours...")
    render json: { status: 'running', message: "Suppression de '#{version}' lancée..." }
  end

  def status
    render json: current_status
  end

  private

    def current_status
      Sidekiq.redis do |r|
        result = r.hgetall(REDIS_KEY)
        {
          status:  result['status']  || 'idle',
          message: result['message'] || '',
          action:  result['action']  || '',
          version: result['version'] || ''
        }
      end
    end

    def running?
      current_status[:status] == 'running'
    end

    def render_busy
      render json: { error: 'Une opération lexicon est déjà en cours.' }, status: :conflict
    end

    def render_invalid_version
      render json: { error: 'Nom de version invalide.' }, status: :unprocessable_entity
    end

    def valid_version?(version)
      version.present? && version.match?(VERSION_FORMAT)
    end

    def reset!
      Sidekiq.redis { |r| r.del(REDIS_KEY) }
    end

    def minio_credentials_present?
      ENV['MINIO_ACCESS_KEY'].to_s != '' && ENV['MINIO_SECRET_KEY'].to_s != ''
    end

    def spawn_task(action, version, initial_message, keep: false)
      Sidekiq.redis do |r|
        r.hmset(REDIS_KEY,
                'status', 'running',
                'message', initial_message,
                'action', action,
                'version', version)
      end

      bundle_bin = Gem.bin_path('bundler', 'bundle')
      env = {
        'RAILS_ENV'   => Rails.env,
        'LEX_ACTION'  => action,
        'LEX_VERSION' => version,
        'LEX_KEEP'    => keep ? 'true' : 'false'
      }
      pid = Process.spawn(
        env,
        bundle_bin, 'exec', 'rake', 'admin:lexicon:run',
        chdir: Rails.root.to_s,
        out:   Rails.root.join('log', 'lexicon.log').to_s,
        err:   Rails.root.join('log', 'lexicon.log').to_s
      )
      Process.detach(pid)
    end
end
