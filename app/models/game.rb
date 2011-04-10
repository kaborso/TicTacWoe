# == Schema Information
# Schema version: 20110405141854
#
# Table name: games
#
#  id         :integer         not null, primary key
#  room       :string(255)
#  pass       :string(255)
#  board      :string(255)
#  choice     :integer
#  turn       :integer
#  status     :integer
#  created_at :datetime
#  updated_at :datetime
#

class Game < ActiveRecord::Base
  #attr_accessor :pass, :board, :choice, :turn, :status  
  #attr_accessible :choice
  
  def self.authenticate_host(id, room)
    host = find_by_id(id)
    (host && host.room == room) ? host : nil
  end 
  
  def self.authenticate_guest(id, pass)
    guest = find_by_id(id)
    (guest && guest.pass == pass) ? guest : nil
  end
  
  def victory?
    lines = Array.new
    arr = self.board.split(',').map {|x| x.to_i}

    lines[0] = arr[0] + arr[1] + arr[2]
    lines[1] = arr[3] + arr[4] + arr[5]
    lines[2] = arr[6] + arr[7] + arr[8]
    lines[3] = arr[0] + arr[3] + arr[6]
    lines[4] = arr[1] + arr[4] + arr[7]
    lines[5] = arr[2] + arr[5] + arr[8]
    lines[6] = arr[0] + arr[4] + arr[8]
    lines[7] = arr[2] + arr[4] + arr[6]
    
    puts lines.join(",")
    lines.each do |x|
      puts x
      if x.abs == 3
        return x/3
      end
    end
    return 0
  end
end
