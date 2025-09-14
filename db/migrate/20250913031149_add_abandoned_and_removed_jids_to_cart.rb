class AddAbandonedAndRemovedJidsToCart < ActiveRecord::Migration[7.1]
  def change
    add_column :carts, :next_abandoned_job_jid, :string
    add_column :carts, :next_removed_job_jid, :string
  end
end
