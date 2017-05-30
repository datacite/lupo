class AddAllocatorToDatacentres < ActiveRecord::Migration[5.1]
  def change
    add_reference :datacentre, :allocator, foreign_key: true
    add_foreign_key :datacentre, :allocator
  end
end
