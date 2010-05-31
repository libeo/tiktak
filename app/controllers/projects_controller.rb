# Handle Projects for a company, including permissions
class ProjectsController < ApplicationController
  before_filter :project_exists, :only => [:edit, :update, :destroy]

  cache_sweeper :project_sweeper, :only => [ :create, :edit, :update, :destroy, :ajax_remove_permission, :ajax_add_permission ]

  private

  def project_exists
    if current_user.admin?
      @project = current_user.company.projects.find(params[:id])
    elsif current_user.create_projects?
      @project = current_user.projects.find(params[:id])
    end

    unless @project
      flash['notice'] = "Error : You are not an admin or project does not exist"
      redirect_from_last
    end
  end

  public

  def new
    if not (current_user.create_projects? or current_user.admin?)
      flash['notice'] = _"You're not allowed to create new projects. Have your admin give you access."
      redirect_from_last
      return
    end
    
    @project = Project.new
  end

  def create
    if not (current_user.create_projects? or current_user.admin?)
      flash['notice'] = _"You're not allowed to create new projects. Have your admin give you access."
      redirect_from_last
      return
    end

    @project = Project.new(params[:project])
    @project.owner = current_user
    @project.company_id = current_user.company_id

    if @project.save

      if params[:copy_project].to_i > 0
        project = current_user.all_projects.find(params[:copy_project])
        project.project_permissions.each do |perm|
          p = perm.clone
          p.project_id = @project.id
          p.save

          if p.user_id == current_user.id
            @project_permission = p
          end
        
        end
      end 
        
      @project_permission ||= ProjectPermission.new

      @project_permission.user_id = current_user.id
      @project_permission.project_id = @project.id
      @project_permission.company_id = current_user.company_id
      @project_permission.can_comment = 1
      @project_permission.can_work = 1
      @project_permission.can_close = 1
      @project_permission.can_report = 1
      @project_permission.can_create = 1
      @project_permission.can_edit = 1
      @project_permission.can_reassign = 1
      @project_permission.can_prioritize = 1
      @project_permission.can_milestone = 1
      @project_permission.can_grant = 1
      @project_permission.save

      current_user.company.default_user_permissions.each do |pp|
        unless @project_permission.user == pp.user
          a = pp.attributes
          a.delete "created_at"
          a.delete "updated_at"
          a[:project_id] = @project.id
          ProjectPermission.new { |proj| proj.update_attributes a }
        end
      end
      
      if @project.company.users.size == 1
        flash['notice'] = _('Project was successfully created.')
        redirect_from_last
      else
        flash['notice'] = _('Project was successfully created. Add users who need access to this project.')
        redirect_to :action => 'edit', :id => @project
      end

      #Notice groups by greg
      NoticeGroup.get_general_groups.each{ |n| n.send_project_notice(@project, current_user) }

    else
      render :action => 'new'
    end
  end

  def create_shortlist_ajax
    if params[:project].nil? || params[:project][:name].nil? || params[:project][:name].empty?
      render :nothing => true
      return
    end
    @project = Project.new(params[:project])
    if session[:filter_customer_short].to_i > 0
      @project.customer_id = session[:filter_customer_short].to_i
    elsif session[:filter_project_short].to_i > 0
      proj = Project.find(:first, :conditions => ["id = ? AND company_id = ?", session[:filter_project_short], current_user.company_id])
      @project.customer_id = proj.customer_id
    elsif session[:filter_milestone_short].to_i > 0
      proj = Milestone.find(:first, :conditions => ["id = ? AND company_id = ?", session[:filter_milestone_short], current_user.company_id]).project
      @project.customer_id = proj.customer_id
    elsif
      render :nothing => true
      return
    end

    @project.owner = current_user
    @project.company_id = current_user.company_id

    if @project.save
      @project_permission = ProjectPermission.new
      @project_permission.user_id = current_user.id
      @project_permission.project_id = @project.id
      @project_permission.company_id = current_user.company_id
      @project_permission.can_comment = 1
      @project_permission.can_work = 1
      @project_permission.can_close = 1
      @project_permission.can_report = 1
      @project_permission.can_create = 1
      @project_permission.can_edit = 1
      @project_permission.can_reassign = 1
      @project_permission.can_prioritize = 1
      @project_permission.can_milestone = 1
      @project_permission.can_grant = 1
      @project_permission.save

      current_user.company.default_user_permissions.each do |pp|
        unless @project_permission.user == pp.user
          a = pp.attributes
          a.delete :created_at
          a[:project_id] = @project.id
          ProjectPermission.new { |proj| proj.update_attributes a }
        end
      end

      session[:filter_customer_short] = "0"
      session[:filter_milestone_short] = "0"
      session[:filter_project_short] = @project.id.to_s

      render :update do |page|
        page.redirect_to :controller => 'tasks', :action => 'shortlist'
      end

      return
    end

    render :nothing => true
  end

  def edit
    @users = User.find(:all, :conditions => ["company_id = ?", current_user.company_id], :order => "users.name")
  end

  def ajax_remove_permission
    permission = ProjectPermission.find(:first, :conditions => ["user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id])
    if permission && (current_user.admin? or permission.project.project_permissions.find(:first, :conditions => {:user_id => current_user.id}).can? 'all')
      if params[:perm].nil?
        permission.destroy
      else
        permission.remove(params[:perm])
        permission.save
      end
    else
      render :update do |page|
        page.visual_effect(:highlight, "user-#{params[:user_id]}", :duration => 1.0, :startcolor => "'#ff9999'")
      end
      return
    end

    if params[:user_edit]
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "/users/project_permissions"
    else 
      @project = permission.project
      @users = Company.find(current_user.company_id).users.find(:all, :order => "users.name")
      render :partial => "permission_list"
    end 
  end

  def ajax_add_permission
    user = User.find(params[:user_id], :conditions => ["company_id = ?", current_user.company_id])

    begin
      if current_user.admin?
        @project = current_user.company.projects.find(params[:id])
      else 
        @project = current_user.projects.find(params[:id])
      end 
    rescue
      render :update do |page|
        page.visual_effect(:highlight, "user-#{params[:user_id]}", :duration => 1.0, :startcolor => "'#ff9999'")
      end
      return
    end

    if @project && current_user && (current_user.admin? or @project.project_permissions.find(:first, :conditions => {:user_id => current_user.id}).can? 'all')
      if @project && user && ProjectPermission.count(:conditions => ["user_id = ? AND project_id = ?", user.id, @project.id]) == 0
        permission = ProjectPermission.new
        permission.user_id = user.id
        permission.project_id = @project.id
        permission.company_id = current_user.company_id
        if current_user.create_projects?
          permission.update_attributes(current_user.perm_template.permissions)
        else
          permission.update_attributes({:can_work => true, :can_comment => true, :can_close => true})
        end
        permission.save
      else
        permission = ProjectPermission.find(:first, :conditions => ["user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id])
        permission.set(params[:perm])
        permission.save
      end
    else
      render :update do |page|
        page.visual_effect(:highlight, "user-#{params[:user_id]}", :duration => 1.0, :startcolor => "'#ff9999'")
      end
      return
    end

    if params[:user_edit] && current_user.admin?
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "users/project_permissions"
    else 
      @users = Company.find(current_user.company_id).users.find(:all, :order => "users.name")
      render :partial => "permission_list"
    end 
  end

  def update
    old_client = @project.customer_id
    old_name = @project.name

    if @project.update_attributes(params[:project])
      # Need to update forum names?
      forums = Forum.find(:all, :conditions => ["project_id = ?", params[:id]])
      if(forums.size > 0 and (@project.name != old_name))

        # Regexp to match any forum named after our project
        forum_name = Regexp.new("\\b#{old_name}\\b")

        # Check each forum object and test against the regexp
        forums.each do |forum|
          if (forum_name.match(forum.name))
            # They have a forum named after the project, so
            # replace the forum name with the new project name
            forum.name.gsub!(forum_name,@project.name)
            forum.save
          end
        end
      end

      # Need to update work-sheet entries?
      if @project.customer_id != old_client
        WorkLog.update_all("customer_id = #{@project.customer_id}", "project_id = #{@project.id} AND customer_id != #{@project.customer_id}")
      end

      flash['notice'] = _('Project was successfully updated.')
      redirect_from_last
    else
      render :action => 'edit'
    end
  end

  def destroy
    @project.pages.destroy_all
    @project.sheets.destroy_all
    @project.tasks.destroy_all
    @project.work_logs.destroy_all
    @project.milestones.destroy_all
    @project.project_permissions.destroy_all
    @project.project_files.each { |p|
      p.destroy
    }

    if session[:filter_project].to_i == @project.id
      session[:filter_project] = nil
    end

    @project.destroy
    flash['notice'] = _('Project was deleted.')
    redirect_from_last
  end

  def complete
    project = Project.find(params[:id], :conditions => ["id IN (#{current_project_ids}) AND completed_at IS NULL"])
    unless project.nil?
      project.completed_at = Time.now.utc
      project.save
      flash[:notice] = _("%s completed.", project.name )
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def revert
    project = current_user.completed_projects.find(params[:id])
    unless project.nil?
      project.completed_at = nil
      project.save
      flash[:notice] = _("%s reverted.", project.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    if current_user.admin?
      @completed_projects = current_user.company.projects.closed.all(:order => "projects.completed_at desc")
    else
      @completed_projects = current_user.completed_projects.can('all').all(:order => 'projects.completed_at desc')
    end
  end

  def list
    options = {
      :order => 'customers.name, projects.name',
      :page => params[:page],
      :include => [:customer, :users],
      :select => 'customers.id, customers.name, projects.name, projects.user_id, projects.created_at, projects.description, users.id, users.name'
    }

    if current_user.admin?
      @projects = current_user.company.projects.open.paginate(:all, options)
      @completed_projects = current_user.company.projects.closed.count(:all)
    else
      @projects = current_user.projects.paginate(:all, options)
      @completed_projects = current_user.completed_projects.can('all').count(:all)
    end
  end

end
