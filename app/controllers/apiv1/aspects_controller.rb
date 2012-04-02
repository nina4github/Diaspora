class Apiv1::AspectsController < Apiv1::BaseController
    require 'active_support/core_ext/hash'
	
    def show
        var=params[:id]
        aspects = @user.aspects
        aspects.each do |aspect|
            if aspect.name.downcase == var.downcase
				render :json =>{:name=>aspect[:name],
                              :id=>aspect[:id],
                              :user_id=>aspect[:user_id]
							  }
				return;
            end
        end 
		render :json=>{:text => "no aspect found", :status => 422 }
    end
    
    #post a new aspect to the current user
    def create
    		if params[:aspectname]
    			  params[:aspect]={:name=>params[:aspectname]}
    		end
        @aspect = @user.aspects.create(params[:aspect])
        
        if @aspect.valid?
           render :json=>{:text => I18n.t('aspects.create.success'), :status => 200 }
        else
           render :json=>{:text => I18n.t('aspects.create.failure'), :status => 422 }
        end
    end
end