namespace :diagrams do
  task all: :environment do
    models = YAML.load_file(Rails.root.join('db', 'models.yml')).map(&:classify).map(&:constantize).delete_if do |m|
      m.superclass != Ekylibre::Record::Base
    end
    graph = Diagram::Model.relational(*models, name: 'all')
    graph.write
  end

  task relational: :environment do
    {
      product: YAML.load_file(Rails.root.join('db', 'models.yml')).select do |m|
        m =~ /^product($|_)/ && m !~ /^product_(group|nature)/ && m.pluralize == m.classify.constantize.table_name
      end.map(&:classify).map(&:constantize) + [Tracking],
      cash: [Cash, CashSession, CashTransfer, BankStatement, BankStatementItem, Deposit, IncomingPaymentMode, OutgoingPaymentMode, Loan, LoanRepayment],
      entity: [Entity, EntityLink, EntityAddress, Task, Event, EventParticipation, Observation, PostalZone, District],
      journal: [Journal, JournalEntry, JournalEntryItem, Account, FinancialYear, AccountBalance, Loan, LoanRepayment, BankStatement, Cash, FixedAsset, FixedAssetDepreciation], # , CashTransfer, CashSession]
      plant_counting: [Plant, Product, PlantCounting, PlantCountingItem, PlantDensityAbacus, PlantDensityAbacusItem, Activity],
      product_nature: [Product, ProductNature, ProductNatureVariant, ProductNatureCategory, ProductNatureVariantReading, ProductNatureCategoryTaxation],
      production: [Activity, ActivityDistribution, Campaign, ActivityProduction, ActivityBudget, TargetDistribution, Intervention, InterventionParameter, InterventionWorkingPeriod, CultivableZone, Product, ActivitySeason, ActivityTactic],
      component: [ProductNature, ProductNatureVariant, ProductNatureVariantComponent, InterventionParameter, Intervention, Product],
      sale: [Sale, SaleNature, SaleItem, Parcel, ParcelItem, Delivery, IncomingPayment, IncomingPaymentMode, Deposit, Affair, Gap, GapItem],
      purchase: [Purchase, PurchaseNature, PurchaseItem, Parcel, ParcelItem, OutgoingPayment, OutgoingPaymentMode, Affair, Gap, GapItem],
      cap_statement: [CapStatement, CapIslet, CapLandParcel, Entity, Campaign],
      delivery: [Delivery, Parcel, ParcelItem, Analysis, DeliveryTool] #
    }.each do |name, models|
      graph = Diagram::Model.relational(*models, name: "#{name}-relational")
      graph.write
      graph = Diagram::Model.physical(*models, name: "#{name}-physical")
      graph.write
    end
  end

  task inheritance: :environment do
    [Product, Affair, InterventionParameter].each do |model|
      graph = Diagram::Model.inheritance(model)
      graph.write
    end
  end

  task nomenclature: :environment do
    Diagram::Nomenclature.inheritance_all(Nomen::Variety)
    graph = Diagram::Nomenclature.inheritance(Nomen::Variety)
    graph.write
  end

  task physical: :environment do
    graph = Diagram::Schema.physical(YAML.load_file(Rails.root.join('db', 'tables.yml')))
    graph.write
  end
end

desc 'Write diagram files of models'
task diagrams: ['diagrams:relational', 'diagrams:inheritance']
