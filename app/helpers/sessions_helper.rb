module SessionsHelper
  
  def join_as_mgr(league, user)
    @membership = Membership.new(:league_id => league.id, :user_id => user.id)
    @membership.credits.current = 0
    @membership.credits.send("#{Time.now.to_s}=", 0)
    @membership.save
    league.update_attributes(:manager => user.id)
  end
  
  def sign_in(user)
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    self.current_user = user
  end
   
  def current_user=(user)
    @current_user = user
  end
  
  def current_user
    @current_user ||= user_from_remember_token
  end
  
  def signed_in?
    !current_user.nil?
  end
  
  def super_user?
    current_user.email == 'fsb.adm.eph@gmail.com'
  end
  
  def manager?(league_id, user_id)
    league = League.find(league_id)
    league.manager == user_id
  end
  
  def in_league?
    league = League.find(params[:id])
    league.users.include?(current_user)
  end
  
  def sign_out
    cookies.delete(:remember_token)
    self.current_user = nil
  end
  
  def current_user?(user)
    user == current_user
  end
  
  def deny_access
    store_location
    redirect_to signin_path, :notice => "Please sign in to access this page"
  end
  
  def not_in_league
    redirect_back_or join_path, "You are not a member of that league, contact the league manager to join!"
  end
  
  def redirect_back_or(default, notice)
    redirect_to (session[:return_to] || default ), :notice => notice
    clear_return_to
  end
  
  private
  
  def user_from_remember_token
    User.authenticate_with_salt(*remember_token)
  end
  
  def remember_token
    cookies.signed[:remember_token] || [nil, nil]
  end
  
  def store_location
    session[:return_to] = request.fullpath
  end
  
  def clear_return_to
    session[:return_to] = nil
  end
  
end
