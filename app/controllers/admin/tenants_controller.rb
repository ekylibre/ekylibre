class Admin::TenantsController < Admin::BaseController
  RESERVED_TENANT_NAMES = %w[admin duke traccar ekylibre].freeze

  def index
    Ekylibre::Tenant.load!
    @tenants = Ekylibre::Tenant.list
    archive_dir = Rails.root.join('tmp', 'archives')
    @archive_info = @tenants.each_with_object({}) do |name, h|
      path = archive_dir.join("#{name}.zip")
      h[name] = path.exist? ? { exists: true, mtime: path.mtime } : { exists: false }
    end
    @tenant_sizes = @tenants.each_with_object({}) do |name, h|
      h[name] = { db: tenant_schema_size(name), files: tenant_files_size(name) }
    end
    if ENV['HOST_DOMAIN_NAME'].present? || Rails.env.development?
      domain = ENV['HOST_DOMAIN_NAME'] || 'ekylibre.localhost'
      @tenant_url = ->(name) { "https://#{name}.#{domain}/" }
    end

    load_lexicon_data
    load_versions_data
  end

  def new
  end

  def create
    current = Admin::CreateTenantJob.current_status
    if current[:status] == 'running'
      render json: { error: "Une création de tenant est déjà en cours (#{current[:tenant]})." }, status: :conflict
      return
    end

    tenant_params = params.require(:tenant).permit(:name, :email, :password, :language, :country, :currency, :send_credentials_email)
    name = tenant_params[:name].to_s.strip.downcase.gsub(/[^a-z0-9_]/, '_')

    if name.blank?
      render json: { error: "Le nom du tenant est invalide." }, status: :unprocessable_entity
      return
    end

    if RESERVED_TENANT_NAMES.include?(name)
      render json: { error: "Le nom '#{name}' est réservé et ne peut pas être utilisé." }, status: :unprocessable_entity
      return
    end

    if Ekylibre::Tenant.exist?(name)
      render json: { error: "Le tenant '#{name}' existe déjà." }, status: :unprocessable_entity
      return
    end

    # Pre-ecriture du statut 'running' AVANT le spawn : evite la race ou le navigateur
    # arrive sur /admin et poll Redis avant que la rake task ait fini de booter Rails
    # (~5-10s) et d'ecrire son propre statut. Sans ca, le banner ne s'affiche pas tant
    # qu'on ne refresh pas manuellement.
    Sidekiq.redis do |r|
      r.hmset(
        Admin::CreateTenantJob::REDIS_KEY,
        'status',  'running',
        'message', "Demarrage de la creation du tenant '#{name}'...",
        'tenant',  name
      )
    end

    env = {
      'RAILS_ENV'        => Rails.env,
      'TENANT_NAME'      => name,
      'TENANT_EMAIL'     => tenant_params[:email].to_s.presence || 'admin@ekylibre.org',
      'TENANT_PASSWORD'  => tenant_params[:password].to_s,
      'TENANT_LANGUAGE'  => tenant_params[:language].to_s.presence || 'fra',
      'TENANT_COUNTRY'   => tenant_params[:country].to_s.presence  || 'fr',
      'TENANT_CURRENCY'  => tenant_params[:currency].to_s.presence || 'EUR',
      'TENANT_SEND_EMAIL' => tenant_params[:send_credentials_email] == '1' ? '1' : '0'
    }

    bundle_bin = Gem.bin_path('bundler', 'bundle')
    pid = Process.spawn(
      env,
      bundle_bin, 'exec', 'rake', 'admin:tenant:create',
      chdir: Rails.root.to_s,
      out:   Rails.root.join('log', 'create_tenant.log').to_s,
      err:   Rails.root.join('log', 'create_tenant.log').to_s
    )
    Process.detach(pid)

    render json: { status: 'running', message: "Création du tenant '#{name}' lancée...", tenant: name }
  end

  def create_status
    render json: Admin::CreateTenantJob.current_status
  end

  def clear_create_status
    Admin::CreateTenantJob.reset!
    head :no_content
  end

  def destroy
    name = params[:id]
    Ekylibre::Tenant.drop(name)
    Admin::LoadDemoJob.reset! if name == Admin::LoadDemoJob::TENANT_NAME
    flash[:notice] = "Tenant '#{name}' supprimé."
    redirect_to admin_root_path
  rescue => e
    flash[:error] = "Erreur lors de la suppression : #{e.message}"
    redirect_to admin_root_path
  end

  def dump
    name = params[:id]
    redis_key = dump_redis_key(name)

    current = Sidekiq.redis { |r| r.hgetall(redis_key) }
    if current['status'] == 'running'
      render json: { error: 'Une archive est déjà en cours de création.' }, status: :conflict
      return
    end

    Sidekiq.redis { |r| r.del(redis_key) }

    bundle_bin = Gem.bin_path('bundler', 'bundle')
    pid = Process.spawn(
      { 'RAILS_ENV' => Rails.env, 'TENANT' => name },
      bundle_bin, 'exec', 'rake', 'admin:dump:run',
      chdir: Rails.root.to_s,
      out:   Rails.root.join('log', 'dump.log').to_s,
      err:   Rails.root.join('log', 'dump.log').to_s
    )
    Process.detach(pid)

    render json: { status: 'running', message: "Création de l'archive '#{name}' en cours..." }
  end

  def dump_status
    name = params[:id]
    result = Sidekiq.redis { |r| r.hgetall(dump_redis_key(name)) }
    archive_path = Rails.root.join('tmp', 'archives', "#{name}.zip")
    archive_exists = result['status'] == 'done' && archive_path.exist?
    render json: {
      status:       result['status'] || 'idle',
      message:      result['message'] || '',
      download:     archive_exists ? dump_download_admin_tenant_path(name) : nil,
      archive_date: archive_exists ? archive_path.mtime.strftime('Générée le %d/%m/%Y à %H:%M') : nil
    }
  end

  def dump_download
    name = params[:id]
    archive_path = Rails.root.join('tmp', 'archives', "#{name}.zip")
    unless archive_path.exist?
      render plain: 'Archive introuvable.', status: :not_found
      return
    end
    send_file archive_path.to_s,
              filename:    "#{name}.zip",
              type:        'application/zip',
              disposition: 'attachment'
  end

  private

    def dump_redis_key(name)
      "ekylibre:admin:dump:#{name}"
    end

    def load_versions_data
      result = Admin::PluginsInspector.new.call
      @ekylibre_version = result.ekylibre_version
      @plugins = result.plugins
    rescue StandardError => e
      Rails.logger.warn("[Admin::Versions] #{e.class}: #{e.message}")
      @ekylibre_version = safe_fetch { Ekylibre::VERSION }
      @plugins = []
    end

    def load_lexicon_data
      @lexicon_active_version  = safe_fetch { LexiconVersion.version }
      @lexicon_target_version  = safe_fetch { File.open(Rails.root.join('.lexicon-version'), &:gets)&.strip }
      @lexicon_version_prefix  = derive_version_prefix(@lexicon_target_version || @lexicon_active_version)
      @lexicon_loaded_versions = safe_fetch([]) { Ekylibre::Lexicon.loaded_versions }
      @lexicon_credentials_present = ENV['MINIO_ACCESS_KEY'].to_s != '' && ENV['MINIO_SECRET_KEY'].to_s != ''
    end

    def safe_fetch(default = nil)
      yield
    rescue StandardError
      default
    end

    def derive_version_prefix(version)
      return nil if version.blank?
      # 6.0.2-innovation → 6.0.2-
      base = version.to_s.split('-').first
      base.present? ? "#{base}-" : nil
    end

    def tenant_schema_size(name)
      quoted = ActiveRecord::Base.connection.quote(name)
      sql = "SELECT SUM(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)))::bigint" \
            " FROM pg_tables WHERE schemaname = #{quoted}"
      result = ActiveRecord::Base.connection.select_one(sql)
      bytes = result['sum'].to_f
      format_tenant_size(bytes)
    rescue
      'N/A'
    end

    def tenant_files_size(name)
      dir = Ekylibre::Tenant.private_directory(name)
      return '0 KB' unless dir.exist?
      bytes = Dir[dir.join('**', '*')].select { |f| File.file?(f) }.sum { |f| File.size(f) }
      format_tenant_size(bytes)
    rescue
      'N/A'
    end

    def format_tenant_size(bytes)
      if bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)} KB"
      else
        "#{(bytes / (1024.0 * 1024)).round(2)} MB"
      end
    end

end
