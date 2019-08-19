class SalesOrderPrinter < SalesEstimateAndOrderPrinter
  def initialize(options)
    super

    self.signatures = WITHOUT_SIGNATURE
    self.parcels = @sale.parcel_items.any? ? [@sale] : WITHOUT_PARCELS
    self.title = I18n.t('labels.export_sales_order')
    self.general_conditions = WITHOUT_CONDITIONS
  end

  def document_nature
    'sales_order'
  end
end
