class CompaniesController < ApplicationController
  #the functio auto_complete_for_user_name is included in the application controller
  before_filter do |controller|
    unless controller.current_user.admin?
      flash['notice'] = _("Only admins can edit company settings.")
      redirect_from_last
    end
  end
  before_filter :set_variables

  def set_variables
    @company = current_user.company
  end

  def edit
  end

  def update
    @internal = @company.internal_customer

    if @internal.nil?
      flash['notice'] = 'Unable to find internal customer.'
      render :action => 'edit'
      return
    end

    @company.set_payperiod_date(params[:company][:payperiod_date], "#{current_user.date_format} #{current_user.time_format}", tz)
    params[:company].delete :payperiod_date
    if @company.update_attributes(params[:company])
      @internal.name = @company.name
      @internal.save

      flash['notice'] = _('Company settings updated')
      redirect_from_last
    else
      render :action => 'edit'
    end 
  end

  def ajax_remove_permission
    if permission = DefaultUserPermission.find(:first, :conditions => ["user_id = ? AND company_id = ?", params[:user_id], current_user.company_id])
      if params[:perm]
        permission.remove params[:perm]
        permission.save
      else
        permission.destroy
      end
    end
    render :partial => "permission_list"
  end

  def ajax_add_permission
    user = User.find(params[:user_id], :conditions => ["company_id = ?", current_user.company_id])

    if user && DefaultUserPermission.count(:conditions => ["user_id = ? AND company_id = ?", user.id, current_user.company_id]) == 0
      permission = DefaultUserPermission.new do |p|
        p.user_id = user.id
        p.company_id = current_user.company_id
        p.can_comment = 1
        p.can_work = 1
        p.can_close = 1
        p.save
      end
    elsif permission = DefaultUserPermission.find(:first, :conditions => ["user_id = ? AND company_id = ?", params[:user_id], current_user.company_id])
      permission.set(params[:perm])
      permission.save
    end
    render :partial => "permission_list"

  end
end
