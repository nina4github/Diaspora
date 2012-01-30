#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class ProfilesController < ApplicationController
  before_filter :authenticate_user!
  def edit
    @person = current_user.person
    @aspect  = :person_edit
    @profile = @person.profile

    @tags = @profile.tags
    @tags_array = []
    @tags.each do |obj| 
      @tags_array << { :name => ("#"+obj.name),
        :value => ("#"+obj.name)}
      end
  end

  def update
    # upload and set new profile photo
    params[:profile] ||= {}
    unless params[:profile][:tag_string].nil? || params[:profile][:tag_string] == I18n.t('profiles.edit.your_tags_placeholder')
      params[:profile][:tag_string].split( " " ).each do |extra_tag|
        extra_tag.strip!
        unless extra_tag == ""
          extra_tag = "##{extra_tag}" unless extra_tag.start_with?( "#" )
          params[:tags] += " #{extra_tag}"
        end
      end
    end
    params[:profile][:tag_string] = (params[:tags]) ? params[:tags].gsub(',',' ') : ""
    params[:profile][:searchable] ||= false
    params[:profile][:photo] = Photo.where(:author_id => current_user.person.id,
                                           :id => params[:photo_id]).first if params[:photo_id]

    if current_user.update_profile params[:profile]
      flash[:notice] = I18n.t 'profiles.update.updated'
      if current_user.getting_started?
        redirect_to getting_started_path
      else
        redirect_to edit_profile_path
      end
    else
      flash[:error] = I18n.t 'profiles.update.failed'
      if params[:getting_started]
        redirect_to getting_started_path(:step => params[:getting_started])
      else
        redirect_to edit_profile_path
      end
    end

  end
<<<<<<< HEAD

=======
  
>>>>>>> 65998bec2a0ab7757c832b9ee5aab44fbd452ee4
  # def show
  #       if params[:id]!=0
  #           @user=User.find(params[:id])
  #       end
  #       @person = @user.person
  #       profile = @person.profile
  #       profiletags = Array.new
  #       profile.tags.each do |tag|
  #           profiletags << tag.name
  #       end
  #       @response = { "id"=>profile.id, 
  #                     "name" => profile.full_name,
  #                     "nichname" => profile.diaspora_handle,
  #                     "preferredUsername" =>@user.username,
  #                     "bithday"=>profile.birthday,
  #                     "gender"=>profile.gender,
  #                     "note" => profile.bio,
  #                     "picture"=>profile.image_url,
  #                     "tags"=>profiletags
  #       }
  #       render :json => {:actor=>@response }
  #    end
end
