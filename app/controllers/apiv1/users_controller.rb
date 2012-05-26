class Apiv1::UsersController < Apiv1::BaseController
    
	#get a users' profile
    def show
		if !@user.nil?
			pieces=@user.email.split("@")
			feedId=pieces.first
			category=pieces[1].split(".").first
			render :json => { "id"=>@user.id, "username" => @user.username, "feedId"=>feedId, "category"=>category}
		else
			render :json => { "text" => "user does not exists", :status=>404 }
		end
    end   
	
    def create
        user=User.new
        user.password=params[:password]
        user.password_confirmation=params[:password_confirmation]
        user.setup(params)
        if user.save
            render :json=> {:id => user.id, :status => 200 }
        else
            user.errors.delete(:person)
            render :json=> {:error => user.create.failure, :status => 422  }
        end
    end
    
    
    def update
      u=params
      # change email notifications
      if u[:email_preferences]
        @user.update_user_preferences(u[:email_preferences])
        flash[:notice] = I18n.t 'users.update.email_notifications_changed'
      # change password
      elsif u[:current_password] && u[:password] && u[:password_confirmation]
        if @user.update_with_password(u)
          password_changed = true
          flash[:notice] = I18n.t 'users.update.password_changed'
        else
          flash[:error] = I18n.t 'users.update.password_not_changed'
        end
      elsif u[:language]
        if @user.update_attributes(:language => u[:language])
          I18n.locale = @user.language
          flash[:notice] = I18n.t 'users.update.language_changed'
        else
          flash[:error] = I18n.t 'users.update.language_not_changed'
        end
      elsif u[:email]
        @user.unconfirmed_email = u[:email]
        if @user.save
            render :json => { "text" => "update success", :status=>200 }
        else
            render :json => { "text" => "update failed", :status=>500 }
        end
      end
    end
    
    def destroy
        Resque.enqueue(Jobs::DeleteAccount, @user.id)
        @user.lock_access!
        render :text => I18n.t('users.destroy'), :status => 200 
    end
end