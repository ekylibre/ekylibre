namespace :maintenance do
  namespace :document_templates do
    desc 'Reload purchases invoice document template'
    task update_purchase_invoice: :environment do
      Ekylibre::Tenant.switch_each do
        if source = DocumentTemplate.template_fallbacks(:purchases_invoice, 'fra').detect(&:exist?)
          File.open(source, 'rb:UTF-8') do |f|
            unless template = DocumentTemplate.find_by(nature: :purchases_invoice, managed: true)
              template = DocumentTemplate.new(nature: :purchases_invoice, managed: true, active: true, by_default: false, archiving: 'last')
            end
            template.attributes = { source: f, language: 'fra' }
            template.name ||= template.nature.l
            template.save!
          end
        end
      end
    end
  end
end
