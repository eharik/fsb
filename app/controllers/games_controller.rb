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
    @league = League.find(params[:league_id])

    @open_bets = Game.open_bets(@league, @selected_game)
    @past_bets =  Game.past_bets(@league, @selected_game).reverse
		@parlays = Game.parlays(@league, @selected_game)
    
    @all_games = Game.all.sort! { |a, b| a.game_time <=> b.game_time }
    @all_games.reverse!
    
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
