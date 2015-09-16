class Backend::SensorsController < Backend::BaseController
  manage_restfully

  unroll

  list do |t|
    t.action :edit
    t.action :destroy
    t.column :active
    t.column :name, url: true
    t.column :vendor_euid
    t.column :model_euid
    t.column :retrieval_mode
    t.column :product, url: true
    t.column :embedded
    t.column :host, url: true
  end

  list :analyses, model: :analysis, conditions: { sensor_id: 'params[:id]'.c } do |t|
    t.column :number, url: true
    t.column :nature
    t.column :state
    t.column :error_explanation
    t.column :sampling_temporal_mode
  end

  def edit
    @sensor = Sensor.find(params[:id])
    @vendor_euid = @sensor.vendor_euid
    @model_euid = @sensor.model_euid

    @models = ActiveSensor::Equipment.equipments_of(@vendor_euid).collect do |equipment|
      [equipment.label, equipment.model]
    end
  end

  def get_models(options = {})
    vendor_euid = params[:vendor_euid]
    models = ActiveSensor::Equipment.equipments_of(vendor_euid).collect do |equipment|
      [equipment.label, equipment.model]
    end

    respond_to do |format|
      format.json { render json: models }
    end
  end

  def get_informations(options = {})
    @vendor_euid = params[:vendor_euid]
    @model_euid = params[:model_euid]

    @models = []

    @equipment = ActiveSensor::Equipment.find(@vendor_euid, @model_euid)

    connection = @equipment.get
    @parameters = connection.controller.parameters

    # Load existing resource for edit
    if params[:id] and params[:id].present?
      @sensor = Sensor.find(params[:id])
      @sensor.access_parameters.symbolize_keys!
    end

    respond_to do |format|
      format.js { render 'sensor' }
    end
  end

  def retrieve
    @sensor = Sensor.find(params[:id])

    unless @sensor.nil?
      SensorReadingJob.perform_later(id: @sensor.id, started_at: Time.now, stopped_at: Time.now)
    end

    redirect_to action: :show, id: params[:id]

  end

end