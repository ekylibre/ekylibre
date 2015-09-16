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
        m =~ /^product($|_)/ and not m =~ /^product_(group|nature)/ and m.pluralize == m.classify.constantize.table_name
      end.map(&:classify).map(&:constantize) + [Tracking],
      cash: [Cash, CashSession, CashTransfer, BankStatement, Deposit, IncomingPaymentMode, OutgoingPaymentMode, Loan, LoanRepayment],
      entity: [Entity, EntityLink, EntityAddress, Task, Event, EventParticipation, Observation, PostalZone, District],
      journal: [Journal, JournalEntry, JournalEntryItem, Account, FinancialYear, AccountBalance, Loan, LoanRepayment, BankStatement, Cash, FixedAsset, FixedAssetDepreciation], # , CashTransfer, CashSession]
      product_nature: [Product, ProductNature, ProductNatureVariant, ProductNatureCategory, ProductNatureVariantReading, ProductNatureCategoryTaxation],
      production: [Activity, ActivityDistribution, Campaign, Production, ProductionBudget, ProductionDistribution, ProductionSupport, Intervention, InterventionCast, Operation],
      sale: [Sale, SaleNature, SaleItem, Parcel, ParcelItem, Delivery, IncomingPayment, IncomingPaymentMode, Deposit],
      purchase: [Purchase, PurchaseNature, PurchaseItem, Parcel, ParcelItem, OutgoingPayment, OutgoingPaymentMode],
      delivery: [Delivery, Parcel, ParcelItem, Analysis] #
    }.each do |name, models|
      graph = Diagram::Model.relational(*models, name: "#{name}-relational")
      graph.write
    end
  end

  task inheritance: :environment do
    [Product, Affair].each do |model|
      graph = Diagram::Model.inheritance(model)
      graph.write
    end
  end

  task nomenclature: :environment do
    Diagram::Nomenclature.inheritance_all(Nomen::Variety)
    # graph = Diagram::Nomenclature.inheritance_all(Nomen::Variety)
    # graph.write
  end
end

desc 'Write diagram files of models'
task diagrams: ['diagrams:relational', 'diagrams:inheritance']
