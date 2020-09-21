class AddGroupingToCategories < ActiveRecord::Migration
  def up
    remove_index :categories, name: "index_categories_on_nct_id_and_name"
    add_column :categories, :grouping, :string, null: false
    add_index :categories, [:nct_id, :name, :grouping], unique: true
  end

  def down
    remove_index :categories, name: "index_categories_on_nct_id_and_name_and_grouping"
    remove_column :categories, :grouping
    add_index :categories, [:nct_id, :name], unique: true
  end
end
