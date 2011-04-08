class AddLockingColumn < ActiveRecord::Migration
  def self.up
    add_column :games, :lock_version, :integer, :default => 0
  end

  def self.down
    remove_column :games, :lock_version
  end
end
