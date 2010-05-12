class SheetsController < ApplicationController
  before_filter :authorized

  private

  def authorized
    @task = Task.find(:first, :conditions => ["tasks.task_num = ? and tasks.project_id in (#{current_project_ids_query})", params[:task_num]])
    unless @task
      flash['notice'] = translate(:no_task_or_access_denied)
      redirect_to :back
    end
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
      @work_log = @current_sheet.task.stop(@current_sheet)
      @current_sheet.destroy
    end

    respond_to do |format|
      #TODO: go check js partial to add notice
      format.html do
        @current_sheet = nil
        redirect_to tasks_path
      end
      format.xml { render :xml => @current_sheet }
      format.js
    end
  end

  def cancel
    @task = nil
    if @current_sheet
      @task = @current_sheet.task
      @current_sheet.destroy
      @current_sheet = nil
    end

    respond_to do |format|
      format.html { redirect_to tasks_path }
      format.xml { render :xml => @task }
      format.js
    end
  end

  def get_update

  end

end
