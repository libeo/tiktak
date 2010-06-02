class SheetsController < ApplicationController
  #Filter in app controller
  before_filter :task_if_allowed, :only => [:start]

  private

  def destroy_sheet
    if @current_sheet
      @old_task = @current_sheet.task
      @work_log = @current_sheet.task.stop(@current_sheet)
      @current_sheet.destroy
    end
  end

  public

  def start
    destroy_sheet
    @current_sheet = Sheet.create({:task => @task, :project => @task.project, :user => current_user})

    respond_to do |format|
      format.html do
        flash['notice'] = "Task #{@task.task_num} started"
        redirect_to tasks_path(@task)
      end
      format.xml { render :xml => @current_sheet }
      format.js #start.js.rjs
    end
  end

  def stop
    @work_log = nil

    if @current_sheet
      @current_sheet.body = params[:description] if params[:descrption] and params[:description].strip != ''
      destroy_sheet
      @current_sheet = nil
    end

    respond_to do |format|
      #TODO: go check js partial to add notice
      format.html do
        flash['notice'] = "Task #{@task.task_num} stopped"
        redirect_to tasks_path(@task)
      end
      format.xml { render :xml => @work_log }
      format.js do
      end
    end
  end

  def cancel
    @task = @current_sheet.task
    destroy_sheet
    @current_sheet = nil

    respond_to do |format|
      format.html do
        flash['notice'] = "Task #{@task.task_num} canceled"
        redirect_to tasks_path(@task)
      end
      format.xml { render :xml => @task }
      format.js
    end
  end

  def updatelog
    @current_sheet.update_attributes({:body => params[:text]})

    respond_to do |format|
      format.html do
        flash['notice'] = "Log updated"
        redirect_to :back
      end
      format.xml { render :xml => @current_sheet }
      format.js
    end
  end

  def refresh
  end

end
