class Apiv1::BaseController < ApplicationController
    #authenticate_with_oauth
    before_filter :set_user_from_oauth
    respond_to :json
    
    def set_user_from_oauth
         #@user = request.env['oauth2'].resource_owner
         if(!params[:username].nil?)
              @user=User.find_by_username(params[:username])
         else
              @user=User.find_by_username(params[:id])
         end
    end
    
    def theAspect
          var=params[:aspect]
          aspects = @user.aspects
          aspects.each do |aspect|
              if aspect.name.downcase == var.downcase
                  return aspect
              end
          end    
    end
end