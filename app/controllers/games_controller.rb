require 'pusher'

Pusher.app_id = '4930'
Pusher.key = 'ad3790b21f7dacec803e'
Pusher.secret = '95fccd84de4182507378'

class GamesController < ApplicationController

  def index    
    render 'index'
  end
  
  def create
    @game = Game.find_by_room(params[:room])   
    if @game == nil
      @game = Game.new({:room => params[:room], :choice => params[:choice]})
      @game.pass = ""
      @game.board = [0,0,0,0,0,0,0,0,0].join(',')
      @game.turn = (rand(2) == 1) ? 1 : -1
      @game.status = 0
      if @game.save
        # Give the host a cookie
        cookies.permanent.signed[:lock] = @game.room
        puts "Game created in room " + cookies.signed[:lock]
        render :partial => 'play.html', :layout => 'game.html', :object => @game, :locals => {:message => (@game.turn == @game.choice) ? "Your Turn" : "Opponent's Turn"} 
        # render "enter"
        # render :text => @game.room
        # redirect_to "/game/"+ @game.room
        # redirect_to :action => 'enter', :room => @game.room
        
      else
      render :text => "Game could not start"
      end
    else
      render :text => "Game already exists #{@game.class}"
    end
  end

  def enter
    puts "Entering the room"
    
    @game = Game.find_by_room(params[:room])
      
    if @game == nil
      redirect_to "/game/new"
    else
      puts @game.inspect.to_s
      # Ask about the host's cookie
      if @game.status == 0
        if cookies.signed[:lock] == @game.room
          if @game.turn == @game.choice
            render :partial => 'play', :layout => 'game', :object => @game, :locals => {:message => "Your Turn"} 
          else
            render :partial => 'play', :layout => 'game', :object => @game, :locals => {:message => "Opponent's Turn"} 
          end
        elsif cookies.signed[:pass] == @game.pass
          # If it's not the host, check if the invitee has joined
          # if so, let him play    
          # Let the invitee into the room and give him a "Your Turn" or "Host's Turn" message
          
          if @game.turn == @game.choice
            render :partial => 'play', :layout => 'game', :object => @game, :locals => {:message => "Opponent's Turn"} 
          else
            render :partial => 'play', :layout => 'game', :object => @game, :locals => {:message => "Your Turn"} 
          end
        elsif @game.pass == ""
          # if not, try to let him in
          begin
            # Update pass in database
            @game.pass = params[:room]
            @game.save
          rescue ActiveRecord::StaleObjectError
            # Game is no longer open, but this user can still spectate
            render :partial => 'look', :layout => 'game', :object => @game, :locals => {:message => "Spectating"} 
          else
            cookies.permanent.signed[:pass] = @game.room          
            if @game.turn == @game.choice
              render :partial => 'play', :layout => 'game', :object => @game, :locals => {:message => "Opponent's Turn"} 
            else
              render :partial => 'play', :layout => 'game', :object => @game, :locals => {:message => "Your Turn"} 
            end
          end
        else
          # Else, if there's no room (or, hah, if the game's over), let the user spectate
          render :partial => 'look', :layout => 'game', :object => @game, :locals => {:message => "Spectating"} 
        end      
      else
      # The game is closed  
      # Use timestamp to display date of the game 
      render :partial => 'look', :layout => 'game', :object => @game, 
      :locals => {:message => "#{@game.updated_at.strftime('%B %d, %Y, %I:%M %p') }"} 
      end
    end
  end
  
  def play        
    if cookies.signed[:lock] == params[:room] || cookies.signed[:pass] == params[:room]
      puts "This player is in this game session"
      @game = Game.find_by_room(params[:room])
      @cell = params[:cell].to_i
      @arr = @game.board.split(',').map {|x| x.to_i}
      
      if @game == nil
        render :text => "Your move failed because the game does not exist."
      else
        if @game.status == 0
          if cookies.signed[:pass] == @game.room
            # Invitee has played a move 
            if @game.choice == @game.turn
              render :text => "0,It's not your turn."
            else
              puts "Invitee marks cell " + @cell.to_s
              if @arr[@cell] == 0
                @arr[@cell] = @game.choice * -1
                @game.turn *= -1
                @game.board = @arr.join(',')
                if @game.save
                  @move = [@cell, @arr[@cell]].join(',')
                  Pusher["tictacwoe"].trigger("mark-cell", @move)
                  puts "Pushed " + @move + " to host"
                  puts "Victory? " + @game.victory?.to_s
                  if @game.victory? != 0 
                    Pusher["tictacwoe"].trigger("game-over", @game.choice * -1)
                    @game.status = 1
                    @game.save
                  end
                  render :text => "1,Opponent's Turn"
                end
              else
                render :text => "0,You can't move there."
              end
            end        
          elsif cookies.signed[:lock] == @game.room
            # Host has played a move         
            if @game.choice == @game.turn         
              if @arr[@cell] == 0
                @arr[@cell] = @game.choice
                @game.turn *= -1
                @game.board = @arr.join(',')
                if @game.save
                  @move = [@cell, @arr[@cell]].join(',')
                  Pusher["tictacwoe"].trigger("mark-cell", @move)
                  puts "Pushed " + @move + " to invitee"
                  puts "Victory?" + @game.victory?.to_s
                  if @game.victory? != 0 
                    Pusher["tictacwoe"].trigger("game-over", @game.choice)
                    @game.status = 1
                    @game.save
                  end
                  render :text => "1,Opponent's Turn"                  
                end
              else
                render :text => "0,You can't move there."
              end                       
            else
              render :text => "0,It's not your turn."
            end 
          end
        else
          render :text => "0,The game has ended."
        end    
      end
    else
      render :text => "You're not a player in this game."
    end  
  end
end