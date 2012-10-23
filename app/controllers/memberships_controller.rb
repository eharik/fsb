class MembershipsController < ApplicationController
  before_filter :authenticate

  
  def new
    @page_title = "Join a League"
    @membership = Membership.new
  end
  
  def create
    league = League.authenticate(params[:membership][:league_name],
                                 params[:membership][:league_password])
    if league.nil?
      flash[:error] = "Invalid league name/password combination."
      redirect_to :controller => :memberships, :action => :new
    elsif league.users.include?(current_user)
      flash[:error] = "You are already a member of the requested league."
      redirect_to :controller => :memberships, :action => :new
    else
      membership = Membership.new(:user_id => current_user.id, :league_id => league.id)
      membership.credits.current = 0
      membership.credits.send("#{Time.now.to_s}=", 0)
      membership.buy_backs = 0
      membership.buy_in = 0
      membership.record = "0/0"
      membership.activate_buy_in = false
      membership.activate_buy_back = false
      membership.save
      league.schedule_games
      league.add_bye_weeks( membership )
      redirect_to :controller => :leagues, :action => :show, :id => league.id
    end
  end
  
  def destroy   
    m= Membership.find(params[:id])
    l = League.find(m.league_id)
    m.delete
    l.schedule_games
    render :nothing => true  
  end
  
  def unlock_buy_in
    @m = Membership.find(params[:id])
    @m.buy_in += 1
    @m.activate_buy_in = true
    @m.save
    @u = User.find(params[:user_id])
    @l = League.find(@m.league_id)
    
    respond_to do |format|
      format.js
    end
  end
  
  def unlock_buy_back
    @m = Membership.find(params[:id])
    @m.buy_backs += 1
    @m.activate_buy_back = true
    @m.save
    @u = User.find(params[:user_id])
    @l = League.find(@m.league_id)

    respond_to do |format|
      format.js
    end
  end
  
  def deploy_credits
    @m = Membership.find(params[:id])
    @l = League.find(@m.league_id)
    @u = User.find(@m.user_id)
    @m.bump_credits(@l)
    @m.activate_buy_back = false
    @m.activate_buy_in = false
    @m.save
    
    respond_to do |format|
      format.js
    end
    
  end
  
  def credit_update
    u = User.find(params[:user_id])
    l = League.find(params[:league_id])
    m = Membership.where(:user_id => u.id, :league_id => l.id).first
    m.su_credit_update(params[:credits].to_f)
    
    render :nothing => true
  end
  
  private
  
    def authenticate
      deny_access unless signed_in?
    end

end
