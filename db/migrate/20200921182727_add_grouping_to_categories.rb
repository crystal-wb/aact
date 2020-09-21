class AddGroupingToCategories < ActiveRecord::Migration
  def up
    add_column :categories, :grouping, :string, null: false
    remove_index :categories, name: "index_categories_on_nct_id_and_name"
    add_index :categories, [:nct_id, :name, :grouping], unique: true
  end

  def down
    remove_column :categories, :grouping
    remove_index :categories, name: "index_categories_on_nct_id_and_name_and_grouping"
    add_index :categories, [:nct_id, :name], unique: true
  end
end
