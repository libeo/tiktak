class ResourcesController < ApplicationController
  before_filter :check_permission

  layout :calc_layout

  # GET /resources
  # GET /resources.xml
  def index
    if params[:filter]
      session[:resource_filters] = params[:filter]
      redirect_to resources_path
    else
      @resources = current_user.company.resources
      @resources = ObjectFilter.new.filter(@resources, 
                                           session[:resource_filters])

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @resources }
      end
    end
  end

  # GET /resources/new
  # GET /resources/new.xml
  def new
    @resource = Resource.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  def show
    redirect_to(params.merge(:action => "edit"))
  end

  # GET /resources/1/edit
  def edit
    @resource = current_user.company.resources.find(params[:id])
  end

  # POST /resources
  # POST /resources.xml
  def create
    @resource = Resource.new
    @resource.company = current_user.company

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:notice] = 'Resource was successfully created.'
        format.html { redirect_to(edit_resource_path(@resource)) }
        format.xml  { render :xml => @resource, :status => :created, :location => @resource }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /resources/1
  # PUT /resources/1.xml
  def update
    @resource = current_user.company.resources.find(params[:id])
    @resource.attributes = params[:resource]
    @resource.company = current_user.company

    respond_to do |format|
      if @resource.save
        # BW: not sure why these aren't getting updated automatically
        @resource.resource_attributes.each { |ra| ra.save }

        flash[:notice] = 'Resource was successfully updated.'
        format.html { redirect_to(edit_resource_path(@resource)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.xml
  def destroy
    @resource = current_user.company.resources.find(params[:id])
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to(resources_url) }
      format.xml  { head :ok }
    end
  end

  # GET /resources/attributes/?type_id=1
  def attributes
    type = current_user.company.resource_types.find(params[:type_id])
    rtas = type.resource_type_attributes

    attributes = rtas.map do |rta| 
      attr = ResourceAttribute.new
      attr.resource_type_attribute = rta
      attr
    end

    render :partial => "attribute", :collection => attributes
  end

  # GET /resources/1/show_password?attr_id=2
  def show_password
    resource = current_user.company.resources.find(params[:id])
    attribute = resource.resource_attributes.find(params[:attr_id])
    
    body = "Requested password for resource "
    body += "#{ resource_path(resource) } - #{ resource.name }"

    wl = WorkLog.new(:user => current_user,
                     :started_at => Time.now.utc,
                     :duration => 0,
                     :comment => 0,
                     :company => current_user.company,
                     :log_type => EventLog::RESOURCE_PASSWORD_REQUESTED,
                     :body => CGI::escapeHTML(body),
                     :comment => true)
    wl.save!
    
    render :text => attribute.value
  end

  def auto_complete_for_resource_parent_id
    search = params[:resource]
    search = search[:parent_id] if search
    @resources = []
    
    if !search.blank?
      cond = [ "lower(name) like ?", "%#{ search.downcase }%" ]
      @resources = current_user.company.resources.find(:all, :conditions => cond)
    end
  end

  private

  def check_permission
    can_view = true
    if !current_user.use_resources?
      can_view = false
      redirect_to(:controller => "activities", :action => "list")
    end

    return can_view
  end

  ###
  # Returns the layout to use to display the current request.
  # Add a "layout" param to the request to use a different layout.
  ###
  def calc_layout
    params[:layout] || "application"
  end
end

