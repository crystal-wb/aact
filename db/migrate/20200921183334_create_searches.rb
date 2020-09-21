class CreateSearches < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.string :grouping, null: false
      t.boolean :make_tsv
      t.string :query, null: false

      t.timestamps null: false
    end
    add_index :searches, [:grouping, :query], unique: true
  end
  
end
