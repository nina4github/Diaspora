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
        
        render :json=> {:username => params[:username],:email => params[:email], :password => params[:password], :password_confirmation => params[:password_confirmation] }
        
    end
    
    def destroy
        Resque.enqueue(Jobs::DeleteAccount, @user.id)
        @user.lock_access!
        render :text => I18n.t('users.destroy'), :status => 200 
    end
end