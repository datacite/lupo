class CreateReferenceRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :reference_repositories do |t|
      t.string :client_id, null:true
      t.string :re3doi, null:true

      t.timestamps
    end
  end
end
