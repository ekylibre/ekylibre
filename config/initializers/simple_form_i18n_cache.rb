# frozen_string_literal: true

# Ruby 3 refuse qu'une variable de classe créée dans une sous-classe soit
# ensuite créée dans la superclasse : « class variable @@x of Sub is overtaken
# by Base ». Or simple_form 4.1 mémoïse ses libellés dans des variables de
# classe posées paresseusement par la première classe qui les réclame — et
# c'est toujours une sous-classe concrète (`StringInput`, `NumericInput`…) qui
# rend un champ la première. Le rendu du deuxième formulaire levait alors
# `RuntimeError` dans la vue.
#
# On pose donc ces variables d'emblée sur les classes qui déclarent l'appel :
# les sous-classes les trouvent ensuite par héritage et n'en créent plus.
# simple_form 5.1 a remplacé ce mécanisme par des variables d'instance de
# classe ; ce fichier disparaîtra avec sa montée.
Rails.application.config.after_initialize do
  SimpleForm::Inputs::Base.translate_required_html
  SimpleForm::Inputs::CollectionInput.boolean_collection
end
