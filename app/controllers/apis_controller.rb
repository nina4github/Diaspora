class ApisController < ApplicationController
  authenticate_with_oauth
  before_filter :set_user_from_oauth
  respond_to :json

  def me
    @person = @user.person
    render :json => {
                      :birthday => @person.profile.birthday,
                      :name => @person.name,
                      :uid => @user.username
                    }
  end

  def status
    render :json => {
      :person => @person.posts
    }
  end
  
  def posts
    render :json => {
      :person => 'posts list'
    }
  end
  
  
  
  
  private
  def set_user_from_oauth
    @user = request.env['oauth2'].resource_owner
  end
  
  
   
end
