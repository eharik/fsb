class UsersController < ApplicationController
  before_filter :authenticate, :only => [:edit, :update, :update]
  before_filter :correct_user, :only => [:edit, :update, :show]
  before_filter :admin_user,   :only => :destroy
  
  def index
    @page_title = "All users"
    @users = User.all
  end
  
  def show
    @user = User.find(params[:id])
    @page_title = @user.name
  end
  
  def new
    @user = User.new
    @page_title = "Sign up"
  end

  def create
    @user = User.new(params[:user])
    @user.updating_password = false
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to Fantasy Sports Book!"
      redirect_to @user
    else
      @page_title = "Sign up"
      render 'new'
    end
  end
  
  def edit
    @user = User.find(params[:id])
    @page_title = "Edit user"
  end
  
  
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated."
      redirect_to @user
    else
      @title = "Edit user"
      render 'edit'
    end
  end
    
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed"
    redirect_to users_path
  end
  
  def list_users
    
  end
  
  
  private
  
    def authenticate
      deny_access unless signed_in?
    end
    
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end
    
    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
