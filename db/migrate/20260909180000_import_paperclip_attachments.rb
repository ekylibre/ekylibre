# frozen_string_literal: true

# Reprise des fichiers écrits par Paperclip vers Active Storage.
#
# Elle doit impérativement précéder DropPaperclipColumns : les colonnes
# <nom>_file_name sont le seul lien restant entre une ligne et son fichier sur
# disque, et l'importeur les lit pour retrouver le nom et le type d'origine.
#
# Placer la reprise dans une migration plutôt que dans une tâche isolée n'est
# pas un détail : elle est ainsi rejouée telle quelle par Fixturing.migrate
# lors de la restauration d'une archive antérieure (cf. tmp/archives), sans que
# le chemin de restauration ait à connaître Paperclip.
#
# Idempotente : un enregistrement dont la pièce jointe est déjà attachée est
# ignoré. La tâche rake attachments:migrate_to_active_storage reste disponible
# pour un rejeu à froid, tant que les colonnes existent encore.
class ImportPaperclipAttachments < ActiveRecord::Migration[5.2]
  def up
    counters = ::Attachments::PaperclipImporter.new(
      logger: ->(line) { say(line, true) }
    ).run

    say(format('%<migrated>d repris, %<missing>d absents, %<skipped>d déjà faits',
               migrated: counters[:migrated], missing: counters[:missing], skipped: counters[:skipped]))
  rescue StandardError => e
    # Une reprise incomplète ne doit pas bloquer la migration du schéma : les
    # fichiers restent sur disque et la tâche rake est rejouable. En revanche
    # la trace doit être visible, sans quoi la perte passerait inaperçue.
    say("ATTENTION : reprise des pièces jointes Paperclip en échec (#{e.class}: #{e.message})")
    Rails.logger.error("[ImportPaperclipAttachments] #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
  end

  def down
    # Les blobs créés ici restent : les supprimer détruirait aussi ceux des
    # pièces jointes déposées depuis.
    say('Rien à défaire : les fichiers Paperclip d\'origine sont restés en place.')
  end
end
