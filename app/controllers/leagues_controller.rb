class LeaguesController < ApplicationController
  before_filter :authenticate, :only => [:new, :create]
  before_filter :league_member, :only => [:show]
  before_filter :league_manager, :only => [:edit, :destroy, :update]
  before_filter :admin_user, :only => [:index, :destroy]
  
  def rules
    
  end
  
  def index
  end
  
  def new
    @league = League.new
    @page_title = "New League"
  end
  
  def create
    @league = League.new(params[:league])
    @user = current_user
    @games = Game.open_games
    if @league.save
      join_as_mgr @league, @user
      render :show
    else
      @page_title = "Sign up"
      render :new
    end
  end
  
  def show
    @page_title = "League Home"
    @league = League.find(params[:id])
    @user = current_user
    @games = Game.open_games
    @membership = Membership.where(:league_id => @league.id, :user_id => @user.id).first
    flash[:notice] = "Place some bets, make some money!"
    
  end
  
  def edit  
  end
  
  def update
  end
  
  def destroy
  end
  
  private
  
    def authenticate
      deny_access unless signed_in?
    end
    
    def league_member
      not_in_league unless in_league?
    end
    
    def league_manager
      deny_access unless league_manager?(params[:id])
    end
    
  def admin_user
    deny_access unless current_user.admin?
  end
  
end
