# frozen_string_literal: true

namespace :attachments do
  desc <<~DESC
    Reprend les fichiers Paperclip dans Active Storage.

    La reprise est normalement faite par la migration ImportPaperclipAttachments,
    qui précède immédiatement la suppression des colonnes. Cette tâche sert au
    rejeu à froid et à l'inventaire — elle n'a plus rien à reprendre une fois les
    colonnes <nom>_file_name supprimées, faute desquelles plus rien ne relie une
    ligne à son fichier.

      TENANT=demo rake attachments:migrate_to_active_storage
      rake attachments:migrate_to_active_storage            # tous les tenants
      DRY_RUN=1 rake attachments:migrate_to_active_storage  # inventaire seul

    La tâche est idempotente : un enregistrement déjà repris est ignoré, ce qui
    la rend rejouable après interruption.
  DESC
  task migrate_to_active_storage: :environment do
    dry_run = ENV['DRY_RUN'].present?
    tenants = ENV['TENANT'].present? ? [ENV['TENANT']] : Ekylibre::Tenant.list

    totals = Hash.new(0)
    tenants.each do |tenant|
      Ekylibre::Tenant.switch(tenant) do
        puts "== #{tenant} ".ljust(72, '=')
        Attachments::PaperclipImporter.new(dry_run: dry_run, logger: method(:puts)).run.each do |key, value|
          totals[key] += value
        end
      end
    end

    puts '=' * 72
    puts format('Total : %<migrated>d repris, %<missing>d fichiers absents, %<skipped>d déjà faits%<suffix>s',
                migrated: totals[:migrated], missing: totals[:missing], skipped: totals[:skipped],
                suffix: dry_run ? ' (DRY_RUN, rien écrit)' : '')
    exit(1) if totals[:missing].positive? && !dry_run
  end
end
