class Apiv1::UsersController < Apiv1::BaseController
    
	#get a users' profile
    def show
		if !@user.nil?
			render :json => { "id"=>@user.id, "username" => @user.username }
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
            render :json=> {:error => user.errors.full_messages.join(";"), :status => 422  }
        end
    end
    
    def destroy
        Resque.enqueue(Jobs::DeleteAccount, @user.id)
        @user.lock_access!
        render :text => I18n.t('users.destroy'), :status => 200 
    end
end