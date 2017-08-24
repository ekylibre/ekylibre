class ExportJob < ActiveJob::Base
  queue_as :default

  def perform(params)
    binding.pry
    params = JSON.load(params)
    klass = Aggeratio[params['id']]
    @aggregator = klass.new(params)
    # Generer le fichier
    # Enregistrer le fichier dans la gestion electronique des documents
    # Envoyer une notification a l'utilisateur
  end
end
