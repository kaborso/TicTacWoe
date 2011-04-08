class CreateGames < ActiveRecord::Migration
  def self.up
    create_table :games do |t|
      t.string  :room
      t.string  :pass
      t.string  :board
      t.integer :choice
      t.integer :turn
      t.integer :status

      t.timestamps
    end
        
  end

  def self.down
    drop_table :games
  end
end
