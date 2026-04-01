class Admin::TenantsController < Admin::BaseController
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
    if Rails.env.development?
      domain = ENV['HOST_DOMAIN_NAME'] || 'ekylibre.lan'
      port   = ENV.fetch('HOST_APP_PORT', 3000)
      @tenant_url = ->(name) { "http://#{name}.#{domain}:#{port}/" }
    end
  end

  def new
  end

  def create
    name = params.require(:tenant).permit(:name, :email, :password, :language, :country, :currency)[:name]
    name = name.to_s.strip.downcase.gsub(/[^a-z0-9_]/, '_')

    if name.blank?
      flash.now[:error] = "Le nom du tenant est invalide."
      return render :new
    end

    if Ekylibre::Tenant.exist?(name)
      flash.now[:error] = "Le tenant '#{name}' existe déjà."
      return render :new
    end

    Ekylibre::Tenant.create(name)
    generated_password = nil

    Ekylibre::Tenant.switch(name) do
      generated_password = initialize_tenant(name)
    end

    msg = "Tenant '#{name}' créé avec succès."
    msg += " Mot de passe admin : #{generated_password}" if generated_password
    flash[:notice] = msg
    redirect_to admin_root_path
  rescue => e
    Ekylibre::Tenant.drop(name) if Ekylibre::Tenant.exist?(name)
    flash.now[:error] = "Erreur lors de la création : #{e.message}"
    render :new
  end

  def destroy
    name = params[:id]
    Ekylibre::Tenant.drop(name)
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

  def initialize_tenant(name)
    tenant_params = params.require(:tenant).permit(:email, :password, :language, :country, :currency)

    language = Onoma::Language.find(tenant_params[:language]).try(:name) || 'fra'
    country  = Onoma::Country.find(tenant_params[:country]).try(:name)   || 'fr'
    currency = Onoma::Currency.find(tenant_params[:currency]).try(:name) || 'EUR'
    email    = tenant_params[:email].presence    || 'admin@ekylibre.org'
    password = tenant_params[:password].presence || SecureRandom.hex(8)

    Preference.set! :language, language
    Preference.set! :country, country
    Preference.set! :currency, currency
    Preference.set! :map_measure_srs, 'WGS84'
    Preference.set! :sales_conditions, ''
    ::I18n.locale = language.to_sym

    Preference.set! :accounting_system, 'fr_pcga2023'
    Account.load_defaults
    Tax.load_defaults
    Unit.load_defaults
    Sequence.load_defaults
    DocumentTemplate.load_defaults
    MapLayer.load_defaults
    NamingFormatLandParcel.load_defaults
    FinancialYear.create!(
      accounting_system: 'fr_pcga2023',
      started_on: Date.new(Time.zone.now.year, 1, 1),
      stopped_on: Date.new(Time.zone.now.year, 12, 31)
    )
    Journal.load_defaults
    SaleNature.load_defaults
    PurchaseNature.load_defaults

    Entity.create!(
      language: language,
      currency: currency,
      nature: :organization,
      of_company: true,
      last_name: name.upcase,
      born_at: Date.new(Time.zone.now.year, 1, 1).to_time
    )

    User.create!(
      email: email,
      administrator: true,
      password: password,
      password_confirmation: password,
      first_name: 'Admin',
      last_name: name
    )

    tenant_params[:password].presence ? nil : password
  end
end
