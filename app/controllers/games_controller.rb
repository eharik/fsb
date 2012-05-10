class GamesController < ApplicationController
  
  def index
    
    if params[:user_id]
      @user = User.find(params[:user_id])
    else
      @user = current_user
    end
     
    if params[:game_id]
      @selected_game = Game.find(params[:game_id])
    else
      @selected_game = Game.last
    end
    
    if DateTime.strptime(@selected_game.game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)").past?
      @all_bets =  Bet.where(:game_id => @selected_game.id)
    else
      @all_bets = []
    end
    
    @all_games = Game.all.reverse
    
    respond_to do |format|
      format.js
      format.html
    end
  end
  
  def new
  end
  
  def create
  end
  
  def show
  end
  
  def edit
  end
  
  def update
  end
  
  def destroy
  end
  
  def list_games
  
  end
end
