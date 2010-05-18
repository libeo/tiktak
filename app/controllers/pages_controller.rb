# Simple Page/Notes system, will grow into a full Wiki once I get the time..
class PagesController < ApplicationController

  def index
    @pages = current_user.pages.all(:select => 'projects.name, pages.id, pages.name', 
  :order => 'projects.name, pages.position', :include => :project).group_by { |p| p.project.name }
  end

  def show
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
  end

  def new
    @page = Page.new
  end

  def create
    @page = Page.new(params[:page])

    @page.user = current_user
    @page.company = current_user.company
    if((@page.project_id.to_i > 0) && @page.save )
      flash['notice'] = _('Note was successfully created.')
      redirect_to :action => 'show', :id => @page.id
    else
      render :action => 'new'
    end
  end

  def edit
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
  end

  def update
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )

    old_name = @page.name
    old_body = @page.body
    old_project = @page.project_id

    if @page.update_attributes(params[:page])
      flash['notice'] = _('Note was successfully updated.')
      redirect_to :action => 'show', :id => @page
    else
      render :action => 'edit'
    end
  end

  def destroy
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
    @page.destroy
    redirect_to :controller => 'tasks', :action => 'list'
  end


end
