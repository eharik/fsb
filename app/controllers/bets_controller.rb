class BetsController < ApplicationController
  
  
  def new
    @bet = Bet.new()
    @bet.game_id = params[:game]
    @bet.bet_type = params[:bet]
    @game = Game.find_by_id(params[:game])
    @league_id = params[:league]
    
    respond_to do |format|
      format.js
    end  
  end
  
  def create
    
    @bet = Bet.new()
    @bet.user_id = current_user
    @bet.league_id = params[:league]
    @bet.game_id = params[:game]
    @bet.bet_type = params[:bet]
    @bet.risk = params[:risk]
    @bet.win = (params[:risk]).to_f * 0.95
    @bet.save
    
    respond_to do |format|
      format.js {flash[:notice] = "Your bet has been submitted!" }
    end 

  end
    
end
