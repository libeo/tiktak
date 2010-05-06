# Handle logins, as well as the portal pages
#
# The portal pages should probably be moved into
# a separate controller.
#
class LoginController < ApplicationController

  layout 'login'

  def index
    render :action => 'login'
  end

  # Display the login page
  def login
    if session[:user_id]
      redirect_to :controller => 'activities', :action => 'list'
    else
      @company = company_from_subdomain
      @news ||= NewsItem.find(:all, :conditions => [ "portal = ?", true ], :order => "id desc", :limit => 3)
    end   
  end

  def logout
    # Mark user as logged out
    ActiveRecord::Base.connection.execute("update users set last_ping_at = NULL, last_seen_at = NULL where id = #{current_user.id}")

    current_user.last_seen_at = nil
    current_user.last_ping_at = nil
    
    # Let other logged in Users in same Company know that User logged out.
    Juggernaut.send("do_execute(#{current_user.id}, \"jQuery('#flash_message').val('#{current_user.username} logged out..');jQuery('flash').show(); new Effect.Highlight('flash_message', {duration:2.0});\");", ["info_#{current_user.company_id}"])

    response.headers["Content-Type"] = 'text/html'

    session[:user_id] = nil
    session[:project] = nil
    session[:sheet] = nil
    session[:filter_user] = nil
    session[:filter_milestone] = nil
    session[:filter_hidden] = nil
    session[:filter_status] = nil
    session[:filter_type] = nil
    session[:filter_severity] = nil
    session[:filter_priority] = nil
    session[:group_tags] = nil
    session[:channels] = nil
    session[:hide_dependencies] = nil
    session[:remember_until] = nil
    session[:redirect] = nil
    session[:history] = nil
    redirect_to "/"
  end

  def validate
  	if params[:forgot] == 'true'
      mail_password
  		redirect_to :action => 'login'
  		return
  	end

    @user = User.new(params[:user])
    @company = company_from_subdomain
    unless logged_in = @user.login(@company)
      flash[:notice] = translate(:login_wrong)
      redirect_to :action => 'login'
      return
    end
    
    # User logged in with correct credentials
    logged_in.last_login_at = Time.now.utc
    
    if params[:remember].to_i == 1
      session[:remember_until] = Time.now.utc + 1.month
      session[:remember] = 1
    else 
      session[:remember] = 0
      session[:remember_until] = Time.now.utc + 1.hour
    end
    logged_in.last_seen_at = Time.now.utc
    logged_in.last_ping_at = Time.now.utc

    logged_in.save
    session[:user_id] = logged_in.id
    
    session[:sheet] = nil
    session[:filter_user] ||= current_user.id.to_s
    session[:filter_project] ||= "0"
    session[:filter_milestone] ||= "0"
    session[:filter_status] ||= "0"
    session[:filter_hidden] ||= "0"
    session[:filter_type] ||= "-1"
    session[:filter_severity] ||= "-10"
    session[:filter_priority] ||= "-10"
    session[:hide_dependencies] ||= "1"
    session[:filter_customer] ||= "0"
    
    # Let others know User logged in
    Juggernaut.send("do_execute(#{logged_in.id}, \"jQuery('#flash_message').val('#{logged_in.username} logged in..');jQuery('flash').show();new Effect.Highlight('flash_message',{duration:2.0});\");", ["info_#{logged_in.company_id}"])

    response.headers["Content-Type"] = 'text/html'

    redirect_from_last
  end

  def shortlist_auth
    return if params[:id].nil? || params[:id].empty?
    user = User.find(:first, :conditions => ["autologin = ?", params[:id]])

    if user.nil?
      render :nothing => true, :layout => false
      return
    end

    session[:user_id] = user.id
    session[:remember_until] = Time.now.utc + ( session[:remember].to_i == 1 ? 1.month : 1.hour )
    session[:redirect] = nil
    authorize

    redirect_to :controller => 'task_shortlist', :action => 'index'

  end

  private

  # Mail the User his/her credentials for all Users on the requested
  # email address
  def mail_password
    if params[:user][:username].strip == ''
      flash[:notice] = translate(:forgot_enter_username)
      return
	end

    @users = User.all(:conditions => ["username = ?", params[:user][:username]])
    if @users.length > 0
      @users.each do |u|
         Signup::deliver_forgot_password(u)
      end
    end

	# tell user it was successful even if we didn't find the user, for security.
    flash[:notice] = translate(:mail_sent)
  end

end
