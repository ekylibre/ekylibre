module Backend::PurchasesHelper

  PURCHASE_STEPS = [
                    {:name => :products,   :actions => [{:controller => 'backend/purchases', :action => :show, :step => :products}, "backend/purchases#new", "backend/purchases#create", "backend/purchases#edit", "backend/purchases#update", "backend/purchase_items#new", "backend/purchase_items#create", "backend/purchase_items#edit", "backend/purchase_items#update", "backend/purchase_items#destroy"], :states => ['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                    {:name => :deliveries, :actions => [{:controller => 'backend/purchases', :action => :show, :step => :deliveries}, "backend/incoming_deliveries#new", "backend/incoming_deliveries#create", "backend/incoming_deliveries#edit", "backend/incoming_deliveries#update"], :states => ['order', 'invoice']},
                    {:name => :summary,    :actions => [{:controller => 'backend/purchases', :action => :show, :step => :summary}], :states => ['invoice']}
                   ].collect{|s| {:name => s[:name], :actions => s[:actions].collect{|u| (u.is_a?(String) ? {:controller => u.split('#')[0].to_sym, :action => u.split('#')[1].to_sym} : u)}, :states => s[:states]}}.freeze

  def purchase_steps(purchase = nil)
    purchase ||= @purchase
    steps_tag(purchase, PURCHASE_STEPS, :name => :purchase)
  end

end
