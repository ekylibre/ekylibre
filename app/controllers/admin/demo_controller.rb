class Admin::DemoController < Admin::BaseController
  def load_demo
    current = Admin::LoadDemoJob.current_status
    if %w[cloning loading].include?(current[:status])
      render json: { error: 'Un chargement est déjà en cours.' }, status: :conflict
      return
    end

    Admin::LoadDemoJob.reset!

    # Spawn a subprocess to avoid Rails code-reloading issues (module tree errors)
    # that occur when running long tasks in a thread within the Rails dev server.
    bundle_bin = Gem.bin_path('bundler', 'bundle')
    pid = Process.spawn(
      { 'RAILS_ENV' => Rails.env },
      bundle_bin, 'exec', 'rake', 'admin:demo:load',
      chdir: Rails.root.to_s,
      out:   Rails.root.join('log', 'demo_load.log').to_s,
      err:   Rails.root.join('log', 'demo_load.log').to_s
    )
    Process.detach(pid)

    render json: { status: 'cloning', message: 'Démarrage...' }
  end

  def status
    render json: Admin::LoadDemoJob.current_status
  end
end
