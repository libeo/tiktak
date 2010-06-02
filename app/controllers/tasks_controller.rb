require 'fastercsv'

class TasksController < ApplicationController
  #filter in app controller
  before_filter :task_if_allowed, :only => [:edit, :show, :update, :destroy, :close, :open, :bookmark]
  before_filter :any_projects, :only => [:new]
  #filter in app controller
  before_filter :admin_only, :only => [:hide, :restore]
  after_filter :set_updater, :except => [:index, :show]
  after_filter :update_juggernaut, :except => [:index, :show]

  private

  # Filter that checks if user has been included in a project
  def any_projects
    unless current_user.projects.can(current_user, :create).size > 0
      respond_to do |format|
        format.html do
          flash['notice'] = translate(:no_projects_available)
          redirect_to :back
        end
        format.xml { render :text => translate(:no_projectes_available), :status => :not_found }
        format.js { render :text => translate(:no_projectes_available), :status => :not_found }
      end
    end
  end

  # Filter that sets the user who updated the task. Used by the Task model when saving a task.
  def set_updater
    @task.updated_by = current_user
  end

  # Sends updates on task modifications through juggernaut
  def update_juggernaut
    @task.send_notifications
    Juggernaut.send("do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
    Juggernaut.send("do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
  end

  public

  def close
    @task.close_task(current_user)

    respond_to do |format|
      format.html do
        flash['notice'] = translate(:task_closed)
        redirect_to tasks_path
      end
      format.xml { render :xml => @task }
      format.js
    end
  end

  def open
    @task.open_task(current_user)

    respond_to do |format|
      format.html do
        flash['notice'] = translate(:task_opened)
        redirect_to tasks_path
      end
      format.xml { render :xml => @task }
      format.js
    end
  end

  # Hides a task so that it no longer appears in task lists, widgets, or searches
  def hide
    @task.update_attributes({:hidden => true})

    respond_to do |format|
      format.html do
        flash['notice'] = translate(:task_hidden)
        redirect_to tasks_path
      end
      format.xml { render :xml => @task }
      format.js
    end
  end

  # Unhides a task that was hidden
  def restore
    @task.update_attributes({:hidden => false})

    respond_to do |format|
      format.html { redirect_to tasks_path}
      format.xml { render :xml => @task }
      format.js 
    end
  end

  # Bookmarks a task so that it appears first in widgets the order by priority
  def bookmark
    bookmarked = params[:bookmarked] || !@task.bookmarked?(current_user) 
    @task.bookmark(current_user, bookmarked)
    @task.save

    respond_to do |format|
      format.html { redirect_to tasks_path }
      format.xml { render :xml => @task }
      format.js { render :text => "" }
    end
  end

  # By default, the index lists all tasks returned by the task filter
  # GET /tasks
  # GET /tasks.xml
  def index

    tf = current_task_filter
    #if tf.qualifiers.length == 0
    #  tf.qualifiers = default_qualifiers
    #  tf.save
    #end

    @tasks = tf.tasks_paginated(nil, :page => params[:page], :select => Task::ROW_SELECT, :include => Task::ROW_INCLUDES)
    session[:channels] += ["tasks_#{current_user.company_id}"]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tasks }
    end
  end

  ## GET /tasks/1
  ## GET /tasks/1.xml
  #def show
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @task }
  #  end
  #end

  # Shows html page to create a new task
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

  # Shows html page to edit a task
  # GET /tasks/1/edit
  def edit
  end

  # Creates a new task using given params
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

  # Updates the details of a task using given params
  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
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

  # Deletes a task PERMANENTLY
  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    @task.destroy

    respond_to do |format|
      format.html { redirect_to(tasks_url) }
      format.xml  { head :ok }
    end
  end

end
