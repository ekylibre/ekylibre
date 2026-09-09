# frozen_string_literal: true

# Suppression des colonnes que Paperclip renseignait.
#
# À ne déployer qu'après ImportPaperclipAttachments — qui la précède
# immédiatement — car ces colonnes portent le nom et le type d'origine des
# fichiers, et sont le seul moyen de les retrouver sur disque.
#
# Les accesseurs <nom>_file_name, <nom>_content_type, <nom>_file_size et
# <nom>_updated_at survivent : LegacyAttachmentColumns les redéfinit à partir de
# l'attachement Active Storage, ce qui évite de réécrire les vues, les
# exchangers et les impressions qui les consomment.
class DropPaperclipColumns < ActiveRecord::Migration[5.2]
  # table => préfixe de l'attachement
  ATTACHMENTS = {
    documents: :file,
    entities: :picture,
    financial_year_exchanges: :import_file,
    guides: :reference_source,
    imports: :archive,
    issues: :picture,
    product_nature_variants: :picture,
    product_natures: :picture,
    products: :picture
  }.freeze

  SUFFIXES = %w[file_name content_type file_size updated_at].freeze

  def change
    ATTACHMENTS.each do |table, prefix|
      SUFFIXES.each do |suffix|
        remove_column table, :"#{prefix}_#{suffix}", column_type_for(suffix)
      end
    end

    # Empreinte MD5 que Paperclip calculait pour dédoublonner les dépôts ;
    # Active Storage tient son propre checksum sur le blob.
    remove_column :documents, :file_fingerprint, :string
  end

  private

    def column_type_for(suffix)
      case suffix
      when 'file_size' then :integer
      when 'updated_at' then :datetime
      else :string
      end
    end
end
