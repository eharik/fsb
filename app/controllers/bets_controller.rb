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
    @user = current_user
    @league = League.find(params[:league])
    @bet = Bet.new()
    @bet.user_id = current_user.id
    @bet.league_id = params[:league]
    @bet.game_id = params[:game]
    @bet.bet_type = params[:bet]
		if params[:risk]
		  @bet.risk = params[:risk]
		  @bet.win = (params[:risk]).to_f * 0.95
		end
    @current_user_membership = Membership.where(:user_id   => current_user.id,
                                               :league_id => params[:league]).first

		if (@bet.bet_type.include? 'lock' )
      @bet.bet_type.slice! '.lock'
			@bet.set_team( Game.find(params[:game]) )
    	@bet.set_bet_value
      @bet.lock = true
      if current_user.has_room_for_locks?( @league )
        if current_user.unique_lock?( @bet )
          @bet.save
          @flash_message = "Lock submitted!"
          flash.now[:notice] = @flash_message
        else
          @flash_message = "You cannot pick the same lock more than once"
          flash.now[:error] = @flash_message
        end
      else
        @flash_message = "Locks for the week have already been picked"
        flash.now[:error] = @flash_message
      end
    else
			@bet.set_team( Game.find(params[:game]) )
	    @bet.set_bet_value
      @bet.lock = false
      if @current_user_membership.sufficient_funds?( params[:risk] )
        @bet.save
        @flash_message = "Your bet has been submitted!"
        flash.now[:notice] = @flash_message
      else
        @flash_message = "Insufficient credits for bet"
        flash.now[:error] = @flash_message
      end
    end
    
    @locks = current_user.this_weeks_locks( @league, @user.id, @league.what_week )
     
    respond_to do |format|
      format.js
    end
  end
  
  def index
    @page_title = "League Bets"
    @league = League.find(params[:league_id])
    
    if params[:user_id]
      @user = User.find(params[:user_id])
    else
      @user = current_user
    end
    
    @membership = Membership.where(:league_id => @league.id, :user_id => @user.id).first  
    @open_bets = Bet.open_bets(@league, @user)
    @past_bets =  Bet.past_bets(@league, @user).reverse
		@parlays = Bet.parlays(@league, @user)
    @all_games = Game.all
    
    respond_to do |format|
      format.js
      format.html
    end
  end

	def parlay_header

    respond_to do |format|
      format.js
      format.html
    end
	end

	def new_parlay
    @bet = Bet.new()
    @bet.game_id = params[:game_id]
    @bet.bet_type = params[:bet_type]
    @game = Game.find_by_id(params[:game_id])
    @league_id = params[:league_id]

		respond_to do |format|
      format.js
      format.html
    end
	end

	def create_parlay
		@bet = Bet.new()
		@bet.user_id = current_user.id
		@bet.league_id = params[:league_id]
		@bet.risk = params[:bet_risk]
		@bet.win = params[:bet_win]
    @bet.lock = false
		@bet.game_id = -1
    @current_user_membership = Membership.where(:user_id   => current_user.id,
                                               :league_id => params[:league_id]).first
		if @current_user_membership.sufficient_funds?( params[:bet_risk] )
      @bet.save
      @flash_message = "Your bet has been submitted!"
      flash.now[:notice] = @flash_message
    else
      @flash_message = "Insufficient credits for bet"
      flash.now[:error] = @flash_message
    end

		respond_to do |format|
			format.json {render :json => @bet.id}
			format.html
		end
	end

	def add_to_parlay
		@bet = Bet.new()
		@bet.user_id = current_user.id
		@bet.parlay_id = params[:parlay_id]
		@bet.league_id = params[:league_id]
		@bet.game_id = params[:game_id]
		@bet.bet_type = params[:bet_type]
		@bet.set_team( Game.find(params[:game_id]) )
    @bet.set_bet_value
    @bet.lock = false
		@bet.save

		@user = current_user
		@league = League.find(params[:league_id])
		@current_user_membership = Membership.where(:user_id   => current_user.id,
                                                :league_id => params[:league_id]).first
    @locks = current_user.this_weeks_locks( @league, @user.id, @league.what_week )
		
		respond_to do |format|
			format.js { render :action => 'create' }
		end
	end
    
end
