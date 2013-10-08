class Backend::WorkersController < Backend::EquipmentsController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
  end

  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :intervention
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end

end
