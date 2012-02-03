class Apiv1::UsersController < Apiv1::BaseController
    
    def create
        user=User.new
        user.password=params[:password]
        user.password_confirmation=params[:password_confirmation]
        user.setup(params)
        if user.save
            user.seed_aspects
            mes=I18n.t 'registrations.create.success'
        else
            user.errors.delete(:person)
            mes=user.errors.full_messages.join(";")
        end
        render :json => {
               :mes => mes
        }
    end
end