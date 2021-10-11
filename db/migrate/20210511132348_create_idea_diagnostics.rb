class CreateIdeaDiagnostics< ActiveRecord::Migration[5.0]
  def change
    create_table :idea_diagnostics do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :state
      t.references :campaign, null: false

      t.stamps
    end

    create_table :idea_diagnostic_results do |t|
    	t.string :overlap_resut
    	t.string :normal_result
    	t.references :idea_diagnostic
    	
    	t.stamps
    end
    
    create_table :idea_diagnostic_items do |t|
    	t.references :idea_diagnostic
    	t.string :name
    	
    	t.stamps
    end
    
    create_table :idea_diagnostic_item_values do |t|
    	t.references :idea_diagnostic_item
    	
    	t.stamps
    end
    
  end
end
