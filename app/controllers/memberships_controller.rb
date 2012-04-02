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
      membership.credits.week1 = 10000
      membership.save
      redirect_to :controller => :leagues, :action => :show, :id => league.id
    end
  end
  
  private
  
    def authenticate
      deny_access unless signed_in?
    end

end
