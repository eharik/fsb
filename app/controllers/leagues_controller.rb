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
      redirect_to @league
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
    @league = League.find(params[:id])
    @page_title = "Edit League"
  end
  
  def update
    @league = League.find(params[:id])
    if @league.update_attributes(params[:league])
      flash[:success] = "League updated."
      redirect_to @league
    else
      @title = "Edit league"
      render 'edit'
    end
  end
  
  def destroy
  end
  
  def list_users
    @league = League.find(params[:league])
    
    respond_to do |format|
      format.js
    end
  end
  
  private
  
    def authenticate
      deny_access unless signed_in?
    end
    
    def league_member
      not_in_league unless in_league?
    end
    
    def league_manager
      deny_access unless manager?(params[:id], current_user.id)
    end
    
  def admin_user
    deny_access unless current_user.admin?
  end
  
end
