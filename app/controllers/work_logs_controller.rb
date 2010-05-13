class WorkLogsController < ApplicationController
  before_filter :allowed, :only => [:edit, :update, :destroy]

  private
  
  def allowed
    if current_user.admin?
      @work_log = current_user.company.work_logs.find(params[:id])
    elsif !(@work_log = current_user.work_logs.find(params[:id]))
      @work_log = WorkLog.find(params[:id])
      @work_log = nil if @work_log and !current_user.can?(@work_log.project, 'all')
    end

    unless @work_log
      flash['notice'] = "Work log does not exist or user does not have access"
      redirect_to :back
    end
  end

  public

  # GET /work_logs
  # GET /work_logs.xml
  def index
    @work_logs = WorkLog.paginate(:page => params[:page], :conditions => ["work_logs.user_id = ? and work_logs.duration > 0", current_user.id], :order => 'started_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @work_logs }
    end
  end

  #GET /work_logs/history/1
  #GET /work_logs/history/1.xml
  def history
    @task = current_user.tasks.find(:first, :conditions => ["tasks.task_num = ?", params[:id]])
    query = ["work_logs.task_id = ?"]
    parms = [@task.id]
    query << "(work_logs.comment = 1 OR work_logs.log_type = 6)" if params[:comments] == "1"

    @work_logs = WorkLog.paginate(:page => params[:page], :conditions => [query.join(" AND "), parms].flatten)

    respond_to do |format|
      format.html #history.html.erb
      format.xml { render :xml => @work_logs }
    end
  end

  # GET /work_logs/1
  # GET /work_logs/1.xml
  def show
    @work_log = current_user.company.work_logs.find(:first, :conditions => ["work_logs.id = ?", params[:id]])
    if @work_log
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @work_log }
      end
    else
      flash['notice'] = "Work log does not exist or user does not have access"
      redirect_to :back
    end
  end

  # GET /work_logs/new
  # GET /work_logs/new.xml
  def new
    @work_log = WorkLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @work_log }
    end
  end

  # GET /work_logs/1/edit
  def edit
  end

  # POST /work_logs
  # POST /work_logs.xml
  def create
    @work_log = WorkLog.new(params[:work_log])

    respond_to do |format|
      if @work_log.save
        flash[:notice] = 'WorkLog was successfully created.'
        format.html { redirect_to(@work_log) }
        format.xml  { render :xml => @work_log, :status => :created, :location => @work_log }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @work_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /work_logs/1
  # PUT /work_logs/1.xml
  def update
    debugger
    respond_to do |format|
      if @work_log.update_attributes(params[:work_log])
        flash[:notice] = 'WorkLog was successfully updated.'
        format.html { redirect_to(@work_log) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @work_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /work_logs/1
  # DELETE /work_logs/1.xml
  def destroy
    @work_log.destroy
    respond_to do |format|
      format.html { redirect_to(work_logs_url) }
      format.xml  { head :ok }
    end
  end

end
