class NoticeGroupsController < ApplicationController
  
  helper_method :worked_nice
  before_filter do |controller|
    unless controller.current_user.admin?
      controller.get_flash['notice'] = _ "You must be an administrator to edit the notice groups"
      controller.redirect_from_last
    end
  end

  def get_flash
    return self.flash
  end
  
  # GET /notice_groups
  # GET /notice_groups.xml
  def list
		redirect_to :index
  end
	
  def index
    @notice_groups = NoticeGroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @notice_groups }
    end
  end
  
  # GET /notice_groups/new
  # GET /notice_groups/new.xml
  def new
    @notice_group = NoticeGroup.new
  end

  # GET /notice_groups/1/edit
  def edit
    @notice_group = NoticeGroup.find(params[:id])
  end

  def set_notice_group(notice)
    p = params[:notice_group]
    notice.name = p[:name]
    notice.duration_format = p[:duration_format]
    notice.message_header = p[:message_header]
    notice.message_subject = p[:message_subject]
    if notice.save
      notice.set_projects(p[:projects]) if p[:projects] and p[:projects].size > 0 
      notice.set_users(p[:users])
    end
  end

  # POST /notice_groups
  # POST /notice_groups.xml
  def create
	p = params[:notice_group]
    @notice_group = NoticeGroup.new { |n| n.name = p[:name] }
    set_notice_group(@notice_group)
    @notice_group.save

    if @notice_group.errors.empty?
      flash[:notice] = _ 'NoticeGroup was successfully created'
      redirect_to :action => "index"
    else
      respond_to do |format|
        format.html { render :action => "new" }
      end
    end
    
    #respond_to do |format|
    #  if valid
    #    flash[:notice] = 'NoticeGroup was successfully created.'
    #    redirect_to :index
    #  else
    #    format.html { render :action => "new" }
    #  end
    #end
  end

  # PUT /notice_groups/1
  # PUT /notice_groups/1.xml
  def update
    @notice_group = NoticeGroup.find(params[:id])
    set_notice_group(@notice_group)

    if @notice_group.errors.empty?
      flash[:notice] = _ 'NoticeGroup was successfully updated'
      redirect_to :action => "index"
    else
      respond_to do |format|
        format.html { render :action => "new" }
      end
    end
  end

  # DELETE /notice_groups/1
  # DELETE /notice_groups/1.xml
  def destroy
    @notice_group = NoticeGroup.find(params[:id])
    @notice_group.destroy

    respond_to do |format|
      format.html { redirect_to(:action => "index") }
      format.xml  { head :ok }
    end
  end

end
