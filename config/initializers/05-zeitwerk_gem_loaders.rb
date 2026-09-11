# frozen_string_literal: true

require 'zeitwerk'

# Rails 6 déclenche `Zeitwerk::Loader.eager_load_all` au chargement hâtif :
# tous les chargeurs Zeitwerk y passent, y compris ceux que les gems
# installent pour elles-mêmes. Une gem dont l'arborescence n'est pas tout à
# fait conforme fait donc échouer le démarrage de l'application en production,
# alors qu'elle fonctionne parfaitement en autochargement paresseux.
#
# `lexicon-common` 0.2.1 est dans ce cas : `lib/lexicon/common/version.rb`
# définit `Lexicon::Common::VERSION`, une constante et non une classe, là où
# son chargeur attend `Lexicon::Common::Version`. La gem est publiée et son
# dépôt ne nous est pas accessible ; on retire donc ce seul fichier du
# chargement hâtif — il reste autochargeable, et rien ne le référence.
#
# À réexaminer à chaque montée de `lexicon-common` : si l'amont corrige le
# fichier, ce bloc devient inutile.
# L'exclusion est posée ici et non dans un `before_eager_load` : la tâche
# `zeitwerk:check` appelle `eager_load_all` directement, sans passer par
# l'initialiseur `:eager_load!` qui déclenche ce hook.
spec = Gem.loaded_specs['lexicon-common']
if spec
  root = File.join(spec.full_gem_path, 'lib', 'lexicon-common.rb')
  # Le registre s'appelait `loaders_managing_gems` jusqu'à Zeitwerk 2.5 et
  # `gem_loaders_by_root_file` depuis la 2.6 ; les deux sont indexés par le
  # fichier racine de la gem.
  registry = Zeitwerk::Registry
  by_root = if registry.respond_to?(:gem_loaders_by_root_file)
              registry.gem_loaders_by_root_file
            else
              registry.loaders_managing_gems
            end
  by_root[root]&.do_not_eager_load(File.join(spec.full_gem_path, 'lib', 'lexicon', 'common', 'version.rb'))
end
