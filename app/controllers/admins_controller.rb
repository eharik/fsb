class AdminsController < ApplicationController
  
  def index
    @page_title = "Admin"
  end
  
  def new
    @admin = Admin.new
    @page_title = "Sign up"
  end
  
  def create
    @admin = Admin.new(params[:user])
    if @admin.save
      sign_in @admin
      flash[:success] = "Welcome to Fantasy Sports Book admin page!"
      redirect_to @admin
    else
      @page_title = "Sign up"
      render 'new'
    end
    @page_title = "Admin"
  end
  
  def show
    @admin = Admin.find(params[:id])
    @page_title = "Admin"
  end
  
  def edit
    @page_title = "Admin"
  end
  
  def update
     @page_title = "Admin"
  end
  
  def destroy
     @page_title = "Admin"
  end
  
end

