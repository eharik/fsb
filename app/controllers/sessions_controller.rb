class SessionsController < ApplicationController
  def new
    if current_user
      if super_user?(current_user)
        redirect_to '/super_user'
        puts '------- Super User ---------'
      else
        redirect_to current_user
      end
    else
      @page_title = "Sign In"
    end
  end
  
  def create
    user = User.authenticate(params[:session][:email].downcase,
                             params[:session][:password])
    if user.nil?
      flash.now[:error] = "Invalid email/password combination"
      @page_title = "Sign In"
      render 'new'
    elsif super_user?(user)
      sign_in user
      redirect_to '/super_user'
    else
      sign_in user
      redirect_back_or user, "Welcome to FSB!"
    end
  end
  
  def destroy
    sign_out
    redirect_to root_path
  end

end
