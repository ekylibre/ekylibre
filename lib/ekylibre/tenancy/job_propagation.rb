module Ekylibre
  module Tenancy
    # Propagation du contexte aux chemins asynchrones (point 1.18).
    #
    # Un job part d'une requête qui connaît sa ferme et s'exécute plus tard,
    # dans un processus qui ne la connaît pas. Sans propagation, il s'exécute
    # sans contexte : la Row Level Security lui rend zéro ligne, et le job
    # échoue — ce qui est le bon échec, mais un échec quand même.
    #
    # Le tenant voyage donc dans la sérialisation du job, comme le fait
    # `apartment-sidekiq` aujourd'hui avec le nom du schéma. À inclure dans
    # `ApplicationJob` le jour où Apartment sort ; d'ici là ce module vit à
    # côté, et ses tests le mettent à l'épreuve.
    module JobPropagation
      extend ActiveSupport::Concern

      included do
        attr_accessor :tenant_id

        around_perform do |job, block|
          if job.tenant_id.present?
            Tenancy.with(job.tenant_id) { block.call }
          else
            # Pas de ferme au moment de l'enfilement : le job est celui d'une
            # tâche d'administration. On le laisse passer sans contexte plutôt
            # que d'en inventer un.
            block.call
          end
        end
      end

      def serialize
        super.merge('tenant_id' => tenant_id || Tenancy.current)
      end

      def deserialize(job_data)
        super
        self.tenant_id = job_data['tenant_id']
      end
    end
  end
end
