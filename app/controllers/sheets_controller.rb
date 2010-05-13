class SheetsController < ApplicationController
  #Filter in app controller
  before_filter :task_if_allowed, :except => [:refresh]

  def start
    if @current_sheet
      @old_task = @current_sheet.task
      @current_sheet.task.stop(@current_sheet)
    end
    @current_sheet = Sheet.create({:task => @task, :project => @task.project, :user => current_user})

    respond_to do |format|
      format.html { redirect_to tasks_path }
      format.xml { render :xml => @sheet }
      format.js #start.js.rjs
    end
  end

  def stop
    @work_log = nil
    if @current_sheet
      @current_sheet.body = params[:description] if params[:descrption] and params[:description].strip != ''
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
      format.js do
        @current_sheet = nil
      end
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

  def updatelog
    @current_sheet.update_attributes({:body => params[:text]})

    respond_to do |format|
      format.html { redirect_to tasks_path }
      format.xml { render :xml => @current_sheet }
      format.js
    end
  end

  def refresh
  end

end
