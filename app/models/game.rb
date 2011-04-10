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
  
  def victory
    
  end
end
