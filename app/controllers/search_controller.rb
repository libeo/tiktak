# Search across all WorkLogs and Tasks
class SearchController < ApplicationController

  def search

    @tasks = []
    @logs = []

    return if params[:query].nil? || params[:query].length == 0

    @keys = params[:query].split(' ')

    # Looking up a task by number?
    task_num = params[:query][/#[0-9]+/]
    unless task_num.nil?
      @tasks = Task.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND task_num = ?", session[:user].company_id, task_num[1..-1]])
      redirect_to :controller => 'tasks', :action => 'edit', :id => @tasks.first
    end

    query = ""
    @keys.each do |k|
      query << "+*:#{k}* "
    end

    # Append project id's the user has access to
    projects = ""
    current_projects.each do |p|
      projects << "|" unless projects == ""
      projects << "#{p.id}"
    end
    projects = "+project_id:\"#{projects}\"" unless projects == ""

    # Find the tasks
    @tasks = Task.find_by_contents("+company_id:#{session[:user].company_id} #{projects} #{query}", {:limit => 1000})

    # Find the worklogs
    @logs = WorkLog.find_by_contents("+company_id:#{session[:user].company_id} #{projects} #{query}", {:limit => 1000})

  end
end
