# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base

  include Misc

  helper_method :last_active
  helper_method :render_to_string
  helper_method :current_user
  helper_method :tz

  before_filter :authorize, :except => [ :login, :validate, :signup, :take_signup, :forgotten_password, :take_forgotten, :show_logo, :rss, :ical, :ical_all, :about, :company_check, :subdomain_check, :unsubscribe, :shortlist_auth ]

  after_filter :set_charset
  after_filter OutputCompressionFilter
  after_filter :after_req_resource_usage
  after_filter :cleanup

  def cleanup
    @user = nil
    @current_projects = nil
    @current_project_ids = nil
    @milestone_ids = nil
    @tz = nil
  end

  def current_user
    unless @user
      @user = User.find(session[:user_id])
    end
    @user
  end

  def tz
    unless @tz
      @tz = Timezone.get(current_user.time_zone)
    end
    @tz
  end



  def after_req_resource_usage
    ps_info = `ps -o psr,etime,pcpu,pmem,rss,vsz -p #{Process.pid} | grep -v CPU`
    ignore, psr, elapsed, pcpu, pmem, rss, vsz = ps_info.split(/\s+/)
    logger.info("pid=#{Process.pid} pcpu=#{pcpu} pmem=#{pmem} rss=#{rss} vsz=#{vsz}")
  end

  # Force UTF-8 for all text Content-Types
  def set_charset
    content_type = headers["Content-Type"] || 'text/html'
    if /^text\//.match(content_type)
      headers["Content-Type"] = "#{content_type}; charset=\"utf-8\""
    end

  end

  # Make sure the session is logged in
  def authorize
    session[:history] ||= []

    # Remember the previous _important_ page for returning to after an edit / update.
    if( request.request_uri.include?('/list') || request.request_uri.include?('/search') || request.request_uri.include?('/edit_preferences') || request.request_uri.include?('/timeline') ) && !request.xhr?
      session[:history] = [request.request_uri] + session[:history][0,3] if session[:history][0] != request.request_uri
    end

#    session[:user_id] = User.find(:first, :offset => rand(1000)).id
#    session[:user_id] = 1

    if session[:user_id].nil?
      subdomain = request.subdomains.first

      # Generate a javascript redirect if user timed out without requesting a new page
      if request.xhr?
        render :update do |page|
          page.redirect_to :controller => 'login', :action => 'login'
        end
      else
        redirect_to "/login/login"
      end
    else
      # Refresh the User object
      # Subscribe general info channel
      session[:channels] = ["info_#{current_user.company_id}"]

      current_user.shout_channels.each do |ch|
        session[:channels] << "channel_passive_#{ch.id}"
      end

      # Refresh work sheet
      session[:sheet] = Sheet.find(:first, :conditions => ["user_id = ?", session[:user_id]], :order => 'id')
      if session[:sheet] && session[:sheet].task.nil?
        session[:sheet].destroy
        session[:sheet] = nil
      end

      # Update last seen, to track online users
      if ['update_sheet_info', 'refresh_channels'].include?(request.path_parameters['action'])
        ActiveRecord::Base.connection.execute("UPDATE users SET last_ping_at='#{Time.now.utc.to_s(:db)}' WHERE id = #{session[:user_id]}")
      else
        ActiveRecord::Base.connection.execute("UPDATE users SET last_seen_at='#{Time.now.utc.to_s(:db)}', last_ping_at='#{Time.now.utc.to_s(:db)}' WHERE id = #{session[:user_id]}")
      end

      # Set current locale
      Localization.lang(current_user.locale || 'en_US')
    end
    true
  end


  # Parse <tt>1w 2d 3h 4m</tt> or <tt>1:2:3:4</tt> => minutes or seconds
  def parse_time(input, minutes = false)
    total = 0
    unless input.nil?
      reg = Regexp.new("(#{_('[wdhm]')})")
      input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when _('w') then total += e.to_i * current_user.workday_duration * 5
          when _('d') then total += e.to_i * current_user.workday_duration
          when _('h') then total += e.to_i * 60
          when _('m') then total += e.to_i
          end
        end
      end

      if total == 0
        times = input.split(':')
        while time = times.shift
          case times.size
          when 0 then total += time.to_i
          when 1 then total += time.to_i * 60
          when 2 then total += time.to_i * current_user.workday_duration
          when 3 then total += time.to_i * current_user.workday_duration * 5
          end
        end
      end

      if total == 0 && input.to_i > 0
        total = input.to_i
        total = total * 60 unless minutes
      end

    end
    total
  end

  def parse_repeat(r)
    # every monday
    # every 15th
    # every last monday
    # every 3rd tuesday
    # every 01/02
    # every 12 days

    r = r.strip.downcase

    return unless r[0..5] == 'every '

    tokens = r[6..-1].split(' ')

    mode = ""
    args = []

    if tokens.size == 1
      Date::DAYNAMES.each do |d|
        if d.downcase == tokens[0]
          mode = "w"
          args[0] = tokens[0]
          break
        end
      end

      if mode == ""
        1.upto(Task::REPEAT_DATE.size) do |i|
          if Task::REPEAT_DATE[i].include? tokens[0]
            mode = 'm'
            args[0] = i
            break
          end
        end
      end

    end


  end


  # Redirect back to the last important page, forcing the tutorial unless that's completed.
  def redirect_from_last
    if session[:history] && session[:history].size > 0
      redirect_to(session[:history][0])
    else
      if current_user.seen_welcome.to_i == 0
        redirect_to('/activities/welcome')
      else
        redirect_to('/activities/list')
      end
    end
  end

  # List of Users current Projects ordered by customer_id and Project.name
  def current_projects
    unless @current_projects
      @current_projects = User.find(session[:user_id]).projects.find(:all, :order => "projects.customer_id, projects.name",
                                                                     :conditions => [ "projects.company_id = ? AND completed_at IS NULL", current_user.company_id ], :include => :customer )
    end
    @current_projects
  end


  # List of current Project ids, joined with ,
  def current_project_ids
    unless @current_project_ids
      @current_project_ids = current_projects.collect(&:id).join(',')
      @current_project_ids = "0" if @current_project_ids == ''
    end
    @current_project_ids
  end

  # List of completed milestone ids, joined with ,
  def completed_milestone_ids
    unless @milestone_ids
      @milestone_ids ||= Milestone.find(:all, :conditions => ["company_id = ? AND completed_at IS NOT NULL", current_user.company_id]).collect{ |m| m.id }.join(',')
      @milestone_ids = "-1" if @milestone_ids == ''
    end
    @milestone_ids
  end

  def worked_nice(minutes)
    format_duration(minutes, current_user.duration_format, current_user.workday_duration)
  end

  def highlight( text, k )
    t = text.gsub(/(#{Regexp.escape(k)})/i, '<strong>\1</strong>')
  end

  def highlight_all( text, keys )
    keys.each do |k|
      text = highlight(text, k)
    end
    text
  end

#  def rescue_action(exception)
#    log_exception(exception)
#    exception.is_a?(ActiveRecord::RecordInvalid) ? render_invalid_record(exception.record) : super
#  end

  def render_invalid_record(record)
    render :action => (record.new_record? ? 'new' : 'edit')
  end

  def admin?
    current_user.admin > 0
  end

  def logged_in?
    true
  end

  def last_active
    session[:last_active] ||= Time.now.utc
  end

  def link_to_task(task)
    t = "<strong><small>#{task.issue_num}</small></strong> <a href=\"/tasks/edit/#{task.id}\" class=\"tooltip#{task.css_classes}\" title=\"#{task.to_tip({ :duration_format => current_user.duration_format, :workday_duration => current_user.workday_duration})}\">#{task.name}</a>"
  end

end
