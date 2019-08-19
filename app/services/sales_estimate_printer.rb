class SalesEstimatePrinter < SalesEstimateAndOrderPrinter
  def initialize(options)
    super

    self.signatures = WITH_SIGNATURE
    self.parcels = WITHOUT_PARCELS
    self.title = I18n.t('labels.export_sales_estimate')
    self.general_conditions = WITH_CONDITIONS
  end

  def document_nature
    'sales_estimate'
  end
end
