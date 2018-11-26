namespace :maintenance do
  namespace :document_templates do
    desc 'Reload purchases invoice document template'
    task update_purchase_invoice: :environment do
      Ekylibre::Tenant.switch_each do
				DocumentTemplate.where(nature: :purchases_invoice).find_each(&:save)
      end
    end
  end
end
