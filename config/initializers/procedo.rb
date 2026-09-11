# Rails 7 n'installe le chargeur principal que dans le *finisher*, après les
# initialiseurs : `Procedo` n'est pas encore autochargeable ici. `to_prepare`
# s'exécute juste après le démarrage, et à chaque rechargement — ce qui est
# souhaitable : le registre tient des classes de procédures autochargées, qui
# deviendraient périmées après un rechargement.
#
# Le registre est remis à neuf à chaque passage, sans quoi les chargeurs
# s'empileraient : `register_loader` concatène.
Rails.application.config.to_prepare do
  registry = Procedo::ProcedureRegistry.new
  registry.register_loader(Procedo::ProcedureLoader.new(root: Procedo.root))
  registry.load
  Ekylibre::Application.instance.instance_variable_set(:@procedo_registry, registry)
end
