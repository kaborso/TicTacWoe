require 'json/pure'
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
      @game.board = JSON.generate([0,0,0,0,0,0,0,0,0])
      @game.turn = (rand(2) == 1) ? 1 : -1
      @game.status = 0
      if @game.save
        # Give the host a cookie
        cookies.permanent.signed[:lock] = @game.room
        puts "Game created in room " + cookies.signed[:lock]
        render :text => @game.room
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
    @message = "games/enter"
    puts "Entering the room"
    
    @game = Game.find_by_room(params[:room])
      
    if @game == nil
      # Flash message
      @message = "No game exists. Start a new one."
      puts @message
      redirect_to "/game/new"
    else
      puts @game.inspect.to_s
      # Ask about the host's cookie
      if @game.status == 0
        if cookies.signed[:lock] == @game.room
          puts "The hosting player has entered"          
          if @game.turn == @game.choice
            @message = "Your Turn"
            puts @message
            render :partial => 'play', :layout => 'game', :object => @game
          else
            @message = "Oppoent's Turn"
            puts @message
            render :partial => 'look', :layout => 'game', :object => @game
          end
        elsif cookies.signed[:pass] == @game.pass
          puts "The invited player has entered"
          # If it's not the host, check if the invitee has joined
          # if so, let him play    
          # Let the invitee into the room and give him a "Your Turn" or "Host's Turn" message
          
          if @game.turn == @game.choice
            @message = "Oppoent's Turn"
            puts @message
            render :partial => 'look', :layout => 'game', :object => @game
          else
            @message = "Your Turn"
            puts @message
            @game.choice *= -1
            render :partial => 'play', :layout => 'game', :object => @game
          end
        elsif @game.pass == ""
          # if not, try to let him in
          puts "Let in the new player"
          begin
            # Update pass in database
            @game.pass = params[:room]
            @game.save
          rescue ActiveRecord::StaleObjectError
            @message = "Game is no longer open, but you can spectate!"
            puts @message
            render :partial => 'look', :layout => 'game', :object => @game
          else
            cookies.permanent.signed[:pass] = @game.room
            
            if @game.turn == @game.choice
              @message = "Oppoent's Turn"
              puts @message
              render :partial => 'look', :layout => 'game', :object => @game
            else
              @message = "Your Turn"
              puts @message
              @game.choice *= -1
              render :partial => 'play', :layout => 'game', :object => @game
            end
          end
        else
          # Else, if there's no room (or, hah, if the game's over), let the user spectate
          @message = "Spectating..."
          puts @message
          render :partial => 'play', :layout => 'game', :object => @game
        end      
      else
      # The game is closed  
      # Use timestamp to display date of the game 
      @message = "Viewing Completed Game from (#{@game.updated_at.to_s})"
      end
    end
  end
  
  def play
    puts "A player is making a move"
    @message =""
        
    if cookies.signed[:lock] == params[:room] || cookies.signed[:pass] == params[:room]
      puts "This player is in this game session"
      @game = Game.find_by_room(params[:room])
      @cell = params[:cell].to_i
      @arr = JSON.parse(@game.board)
      
      if @game == nil
        render :text => "Your play failed because the game does not exist."
      else
        if cookies.signed[:pass] == @game.room
          # Invitee has played a move
          if @game.choice == @game.turn
            # It's not his turn
          else
            puts "Invitee marks cell " + @cell.to_s
            if(@arr[@cell] == 0)
              @arr[@cell] = @game.choice * -1
              @game.turn *= -1
              @game.board = @arr.to_s
              if @game.save
                @move = JSON.generate([@cell, @arr[@cell]])
                Pusher["tictacwoe"].trigger("mark-cell", @move)
                puts "Pushed " + @move + " to host"
                render :text => "Opponent's turn"
              end
            else
              render :text => "Invalid move"
            end
          end
        elsif cookies.signed[:lock] == @game.room
          # Host has played a move
          if @game.choice == @game.turn         
            if(@arr[@cell] == 0)
              @arr[@cell] = @game.choice
              @game.turn *= -1
              @game.board = @arr.to_s
              if @game.save
                @move = JSON.generate([@cell, @arr[@cell]])
                Pusher["tictacwoe"].trigger("mark-cell", @move)
                puts "Pushed " + @move + " to invitee"
                render :text => "Opponent's turn"
              end
            else
              render :text => "Invalid move"
            end                       
          else
            # It's not his turn
          end
        end
      end

      # render :partial => 'look', :layout => 'enter', :object => @game, 
      #        :locals => { :message => @message }      
    else
      render :text => "You are not a player in this game."
    end
  end
end