class CreateVirtualComments < ActiveRecord::Migration
  def self.up
    create_table :virtual_comments do |t|
      t.integer :time_booking_id
      t.string :comments
    end
  end

  def self.down
    drop_table :virtual_comments
  end
end