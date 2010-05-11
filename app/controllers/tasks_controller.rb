require 'fastercsv'

class TasksController < ApplicationController
  before_filter :allowed, :only => [:edit, :show, :update, :destroy, :start, :stop, :close, :open]
  before_filter :any_projects, :only => [:new]
  before_filter :admin_only, :only => [:hide, :restore]
  after_filter :set_updater, :except => [:index, :start, :stop, :show]
  after_filter :update_juggernaut

  private

  def admin_only
    unless current_user.admin?
      flash['notice'] = translate(:admin_only)
      redirect_to :back
    end
  end

  def allowed
    if current_user.admin?
      @task = current_user.company.tasks.find_by_task_num(params[:task_num])
    else
      @task = Task.find(:first, :conditions => ["tasks.task_num = ? and tasks.project_id in (#{current_project_ids_query})", params[:task_num]])
    end

    unless @task
      flash['notice'] = translate(:no_task_or_access_denied)
      redirect_to :back
    end
  end

  def any_projects
    unless current_user.projects.can(current_user, :create).size > 0
      flash['notice'] = translate(:no_projects_available)
      redirect_to :back
    end
  end

  def set_updater
    @task.updated_by = current_user
  end

  def update_juggernaut
    Juggernaut.send("do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
    Juggernaut.send("do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
  end

  public

  def start
    @current_sheet.task.stop(@current_sheet) if @current_sheet
    @current_sheet = Sheet.new({:task => @task, :project => @task.project, :user => current_user})

    respond_to do |format|
      format.html { redirect_to tasks_path }
      format.xml { render :xml => @sheet }
      format.js #start.js.rjs
    end
  end

  def stop
    if @current_sheet
      @current_sheet.task.stop(@current_sheet)
      @current_sheet.destroy
      @current_sheet = nil
    end

    respond_to do |format|
      #TODO: go check js partial to add notice
      format.html { redirect_to tasks_path }
      format.xml { render :xml => @sheet }
      format.js
    end
  end

  def hide
    @task.update_attributes {:hidden => true}

    respond_to do |format|
      format.html { redirect_to tasks_path }
      format.xml { render :xml => @task }
      format.js
    end
  end

  def restore
    @task.update_attributes {:hidden => false}

    respond_to do |format|
      format.html { redirect_to tasks_path}
      format.xml { render :xml => @task }
      format.js 
  end

  def bookmark
    bookmarked = params[:bookmarked] || !@task.bookmarked?(current_user) 
    @task.bookmark(bookmarked)
    @task.save

    format.html { redirect_to tasks_path }
    format.xml { render :xml => @task }
    format.js
  end

  # GET /tasks
  # GET /tasks.xml
  def index
    @tasks = Task.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tasks }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    @task = Task.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @task }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    @task = current_user.company.tasks.new
    #TODO: add association builds if needed for nested models ?

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task }
    end
  end

  # GET /tasks/1/edit
  def edit
    @task = Task.find(params[:id])
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    @task = current_user.company.tasks.new(params[:task])

    respond_to do |format|
      if @task.save
        flash[:notice] = 'Task was successfully created.'
        format.html { redirect_to(@task) }
        format.xml  { render :xml => @task, :status => :created, :location => @task }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    @task = Task.find(params[:id])

    respond_to do |format|
      if @task.update_attributes(params[:task])
        flash[:notice] = 'Task was successfully updated.'
        format.html { redirect_to(@task) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    @task = Task.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.html { redirect_to(tasks_url) }
      format.xml  { head :ok }
    end
  end
end
