class Admin::RestoreController < Admin::BaseController
  REDIS_KEY = 'ekylibre:admin:restore'.freeze

  def create
    if current_status[:status] == 'running'
      render json: { error: 'Une restauration est déjà en cours.' }, status: :conflict
      return
    end

    unless params[:archive].present?
      render json: { error: "Veuillez sélectionner un fichier d'archive." }, status: :unprocessable_entity
      return
    end

    file = params[:archive]
    archive_dir = Rails.root.join('tmp', 'archives')
    FileUtils.mkdir_p(archive_dir)
    filename     = File.basename(file.original_filename)
    archive_path = archive_dir.join(filename)
    File.binwrite(archive_path, file.read)

    tenant_name = File.basename(filename, '.*')

    reset!
    bundle_bin = Gem.bin_path('bundler', 'bundle')
    pid = Process.spawn(
      { 'RAILS_ENV' => Rails.env, 'ARCHIVE' => archive_path.to_s, 'TENANT' => tenant_name },
      bundle_bin, 'exec', 'rake', 'admin:restore:run',
      chdir: Rails.root.to_s,
      out:   Rails.root.join('log', 'restore.log').to_s,
      err:   Rails.root.join('log', 'restore.log').to_s
    )
    Process.detach(pid)

    render json: { status: 'running', message: "Restauration de '#{tenant_name}' lancée..." }
  end

  def status
    render json: current_status
  end

  private

    def current_status
      Sidekiq.redis do |r|
        result = r.hgetall(REDIS_KEY)
        { status: result['status'] || 'idle', message: result['message'] || '' }
      end
    end

    def reset!
      Sidekiq.redis { |r| r.del(REDIS_KEY) }
    end
end
