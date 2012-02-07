class Apiv1::AspectsController < Apiv1::BaseController
    
    # GET a list of all aspects for a user
    def index
        render :json => {
              :aspects => @user.aspects       
        }
    end
    
    #post a new aspect to the current user
    def show
		render :json=>{:text=>params[:aspect] }
        #@aspect = @user.aspects.create(params[:aspect])
       
        if @aspect.valid?
            render :text => I18n.t('aspects.create.success'), :status => 200 
        else
            render :text => I18n.t('aspects.create.failure'), :status => 422 
        end
    end
end