namespace :admin do
  namespace :demo do
    desc 'Clone demo-data repo and load demo first_run (tracks progress in Redis)'
    task load: :environment do
      require 'ekylibre/first_run'

      redis_key   = 'ekylibre:admin:demo'
      demo_repo   = 'https://github.com/ekylibre/demo-data.git'
      demo_folder = 'demo'
      tenant_name = 'demo'
      loader_labels = {
        'base'            => 'Paramètres de base',
        'entities'        => 'Entités / Contacts',
        'land_parcels'    => 'Parcelles',
        'buildings'       => 'Bâtiments',
        'equipments'      => 'Équipements',
        'workers'         => 'Employés',
        'products'        => 'Produits',
        'animals'         => 'Animaux',
        'productions'     => 'Productions',
        'analyses'        => 'Analyses',
        'sales'           => 'Ventes',
        'deliveries'      => 'Livraisons',
        'purchases'       => 'Achats',
        'bank_statements' => 'Relevés bancaires',
        'cash_transfers'  => 'Virements',
        'interventions'   => 'Interventions',
        'accountancy'     => 'Comptabilité'
      }

      set_status = lambda do |status, message, step = nil, total = nil|
        Sidekiq.redis do |r|
          args = [redis_key, 'status', status, 'message', message.to_s]
          args += ['step', step.to_s, 'total_steps', total.to_s] if step && total
          r.hmset(*args)
        end
      end

      # -- Step 1: Clone if needed --
      first_runs_path = Rails.root.join('db', 'first_runs')
      demo_path       = first_runs_path.join(demo_folder)
      FileUtils.mkdir_p(first_runs_path)

      unless demo_path.exist?
        set_status.call('cloning', 'Clonage du dépôt demo-data...')
        tmp_path = Rails.root.join('tmp', "demo-data-#{Process.pid}")
        begin
          success = system('git', 'clone', '--depth', '1', '--quiet', demo_repo, tmp_path.to_s)
          raise "Échec du clonage git (code #{$?.exitstatus})" unless success

          cloned_demo = tmp_path.join(demo_folder)
          raise "Dossier '#{demo_folder}' introuvable dans le dépôt cloné." unless cloned_demo.exist?

          FileUtils.mv(cloned_demo.to_s, demo_path.to_s)
        ensure
          FileUtils.rm_rf(tmp_path.to_s)
        end
      end

      # -- Step 2: Hook progress into FirstRun::Base#run_loader --
      total = loader_labels.size
      step  = 0

      unless Ekylibre::FirstRun::Base.ancestors.include?(Ekylibre::FirstRun::ProgressTracker)
        Ekylibre::FirstRun::Base.prepend(Ekylibre::FirstRun::ProgressTracker)
      end

      Thread.current[:first_run_progress] = lambda do |loader_name|
        step += 1
        label = loader_labels[loader_name.to_s] || loader_name.to_s.humanize
        set_status.call('loading', label, step, total)
      end

      set_status.call('loading', 'Démarrage du chargement...', 0, total)

      # -- Step 3: Launch first_run in global transaction --
      begin
        Ekylibre::FirstRun.launch!(
          folder:  demo_folder,
          name:    tenant_name,
          verbose: false,
          hard:    false
        )
      rescue => e
        Ekylibre::Tenant.drop(tenant_name) if Ekylibre::Tenant.exist?(tenant_name)
        set_status.call('error', "Erreur : #{e.message}")
        raise
      ensure
        Thread.current[:first_run_progress] = nil
      end

      set_status.call('done', "Le tenant '#{tenant_name}' est prêt.", total, total)
    end
  end
end

# Progress hook module (also used by the rake task)
module Ekylibre
  module FirstRun
    module ProgressTracker
      def run_loader(loader, imports)
        Thread.current[:first_run_progress]&.call(loader)
        super
      end
    end
  end
end
