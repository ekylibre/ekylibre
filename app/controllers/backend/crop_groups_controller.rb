module Backend
  class CropGroupsController < Backend::BaseController
    manage_restfully

    unroll

    before_action :kujaku_options, only: %i[index]

    def kujaku_options
      @labels = Label.joins(:crop_group_labellings).where.not(crop_group_labellings: { crop_group_id: nil }).distinct
    end

    def self.crop_groups_conditions
      code = ''
      code << search_conditions(crop_groups: %i[name target], labels: %i[name], products: %i[name]) + " ||= []\n"
      code << "unless params[:label].blank? \n"
      code << "  c[0] << ' AND labels.name = ?'\n"
      code << "  c << params[:label]\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list selectable: true, conditions: crop_groups_conditions, joins: "LEFT JOIN crop_group_labellings ON crop_group_labellings.crop_group_id = crop_groups.id
      LEFT JOIN labels ON labels.id = crop_group_labellings.label_id
      LEFT JOIN crop_group_items ON crop_group_items.crop_group_id = crop_groups.id
      LEFT JOIN products ON products.id = crop_group_items.crop_id ", distinct: true do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.action :duplicate, method: :post
      t.column :name, url: true
      t.column :uses, label_method: :label_names, label: :use
      t.column :crop_names, label_method: :crop_names, label: :land_parcels_plants
      t.column :total_area, label_method: :total_area, label: :total_area
    end

    list(:interventions, joins: { targets: { product: :crop_groups } }, conditions: ['crop_groups.id = ?', 'params[:id]'.c], order: { created_at: :desc }, line_class: :status, distinct: true) do |t|
      t.column :name, url: true
      t.column :started_at
      t.column :human_working_duration
      t.column :human_target_names
      t.column :human_working_zone_area
      t.column :stopped_at, hidden: true
      t.column :issue, url: true
    end

    list(:plants, joins: :crop_groups, conditions: ['crop_groups.id = ?', 'params[:id]'.c], order: { name: :asc }, line_class: :status) do |t|
      t.column :name, url: true
      t.column :work_number, hidden: true
      t.column :variety
      t.column :work_name, through: :container, hidden: true, url: true
      t.column :net_surface_area, datatype: :measure
      t.status
      t.column :born_at
      t.column :dead_at
    end

    list(:productions, model: :activity_production, joins: { support: :crop_groups }, conditions: ['crop_groups.id = ?', 'params[:id]'.c], order: { started_on: :desc }) do |t|
      t.column :name, url: true
      t.column :activity_name, label: :activity, url: true
      t.column :support_name, label: :support, url: true
      t.column :usage
      t.column :grains_yield, datatype: :measure
      t.column :started_on
      t.column :stopped_on
    end

    def duplicate
      return unless crop_group = find_and_check

      duplicate_cg = duplicate_crop_group(crop_group)
      duplicate_cg.save!

      redirect_to action: :index
    end

    private

      def duplicate_crop_group(crop_group)
        index = crop_group.class.where('name like ?', "#{crop_group.name}%").count
        new_crop_group = crop_group.dup.tap { |dup| dup.name = "#{crop_group.name} (#{index})" }
        new_crop_group.items.build(
          crop_group.items.map {|item| item.dup.attributes }
        )
        new_crop_group.labellings.build(
          crop_group.labellings.map {|item| item.dup.attributes }
        )
        new_crop_group
      end
  end
end
