class UsersController < ApplicationController
  before_filter :authenticate, :only => [:edit, :update]
  before_filter :correct_user, :only => [:edit, :update, :show]
  before_filter :admin,        :only => [:destroy, :super_user, :su_credit_update]
  
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
    @user.email = @user.email.downcase
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
  
  def super_user
    @l = League.all
  end
  
  def su_settings
    @l = League.find(params[:id])
    
    respond_to do |format|
      format.js
    end 
  end
  
  def su_users
    @l = League.find(params[:id])
    @u = @l.users

    respond_to do |format|
      format.js
    end
  end
  
  def su_credit_update
    
  end
  
  private
  
    def authenticate
      deny_access unless signed_in?
    end
    
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end
    
    def admin
      redirect_to(root_path) unless super_user?
    end
end
