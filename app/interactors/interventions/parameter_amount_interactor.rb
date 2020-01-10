module Interventions
  class ParameterAmountInteractor
    def self.call(params)
      interactor = new(params)
      interactor.run
      interactor
    end

    attr_reader :intervention, :product, :quantity, :unit_name,
                :error, :amount_computation

    def initialize(params)
      @intervention = params[:intervention]
      @unit_name = params[:unit_name]

      @quantity = params[:quantity].to_d if params[:quantity].present?
      @product = Product.find(params[:product_id]) if params[:product_id].present?
    end

    def run
      if @product.nil? || @quantity.nil? || @unit_name.nil?
        init_param_error
        return
      end

      begin
        @amount_computation = Interventions::Costs::InputService
                              .new(product: @product)
                              .perform(quantity: @quantity,
                                       unit_name: @unit_name)
      rescue StandardError => exception
        fail!(exception.message)
      end
    end

    def success?
      @error.nil?
    end

    def fail?
      !@error.nil?
    end

    def human_amount
      @amount_computation.human_amount
    end

    def failed_amount_computation
      InterventionParameter::AmountComputation.failed
    end

    private

    def fail!(error)
      @error = error
    end

    def init_param_error
      fail!('Product param is missing') if @product.nil?
      fail!('Quantity param is missing.') if @quantity.nil?
      fail!('Unit_name param is missing.') if @unit_name.nil?
    end
  end
end
