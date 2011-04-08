class SetDefaultPassValue < ActiveRecord::Migration
  def self.up
    Game.update_all ["pass = ?", ""]
  end

  def self.down
  end
end
