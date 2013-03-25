module Backend::SalesHelper

  SALE_STEPS = [
                {:name => :products,   :actions => [{:controller => 'backend/sales', :action => :show, :step => :products}, "backend/sales#new", "backend/sales#create", "backend/sales#edit", "backend/sales#update", "backend/sale_items#new", "backend/sale_items#create", "backend/sale_items#edit", "backend/sale_items#update", "backend/sale_items#destroy"], :states => ['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                {:name => :deliveries, :actions => [{:controller => 'backend/sales', :action => :show, :step => :deliveries}, "backend/outgoing_deliveries#show", "backend/outgoing_deliveries#new", "backend/outgoing_deliveries#create", "backend/outgoing_deliveries#edit", "backend/outgoing_deliveries#update"], :states => ['order', 'invoice']},
                {:name => :summary,    :actions => [{:controller => 'backend/sales', :action => :show, :step => :summary}], :states => ['invoice']}
               ].collect{|s| {:name => s[:name], :actions => s[:actions].collect{|u| (u.is_a?(String) ? {:controller => u.split('#')[0].to_sym, :action => u.split('#')[1].to_sym} : u)}, :states => s[:states]}}.freeze

  def sale_steps(sale = nil)
    sale ||= @sale
    steps_tag(sale, SALE_STEPS, :name => :sale)
  end

end
