class Apiv1::BaseController < ApplicationController
    #authenticate_with_oauth
    before_filter :set_user_from_oauth
    respond_to :json
    
    def set_user_from_oauth
         #@user = request.env['oauth2'].resource_owner
         @user=User.find_by_username(params[:user])
    end
    
    def theAspect
          var=params[:aspect]
          aspects = @user.aspects
          aspects.each do |aspect|
              if var.is_a? Integer && aspect.id == var
                  return aspect
              elsif var.is_a? String && aspect.name.downcase == var.downcase
                  return aspect
              end
          end    
    end
end