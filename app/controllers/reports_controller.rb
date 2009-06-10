require "fastercsv"
# Massage the WorkLogs in different ways, saving reports for later access
# as well as CSV downloading.
#
class ReportsController < ApplicationController
  TIMESHEET = 3

  def list
    sql_filter = ""
    date_filter = ""

    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids})
    @users = User.find(:all, :order => 'name', :conditions => ['users.company_id = ?', current_user.company_id], :joins => "INNER JOIN project_permissions ON project_permissions.user_id = users.id")
    
    if options = params[:report]
      report = WorklogReport.new(self, options)
      start_date = report.start_date
      end_date = report.end_date
      @type = report.type

      @logs = report.work_logs
      @logs = filter_logs_by_params(@logs, params)

      start_date = report.start_date
      end_date = report.end_date

      @row_value = options[:rows]
      @row_value = @row_value.to_i == 0 ? @row_value : @row_value.to_i
      @column_value = options[:columns]
      @column_value = @column_value.to_i == 0 ? @column_value : @column_value.to_i

      
      @range = report.range

      @total = 0
      @row_totals = { }
      @column_totals = { }
      @column_headers = { }
      @rows = { }

      if start_date
        @column_headers[ '__' ] = "#{start_date.strftime_localized(current_user.date_format)}"
        @column_headers[ '__' ] << "- #{end_date.strftime_localized(current_user.date_format)}" if end_date && end_date.yday != start_date.yday
      else
        @column_headers[ '__' ] = "&nbsp;"
      end

      for w in @logs
        next if (w.task_id.to_i == 0) || w.duration.to_i == 0
        @total += w.duration

        case @type

        when 1, 4
          # Pivot
          if @column_value == 2 && !w.task.tags.empty?
            w.task.tags.each do |tag|
              key = key_from_worklog(tag, @column_value).to_s
              unless @column_headers[ key ]
                @column_headers[ key ] = name_from_worklog( tag, @column_value )
                @column_totals[ key ] ||= 0
              end
              do_column(w, key)
            end
          else
            key = key_from_worklog(w, @column_value).to_s
            unless @column_headers[ key ]
              @column_headers[ key ] = name_from_worklog( w, @column_value )
              if @column_value == 1
                @column_headers[ key ] = w.task.name
              end
              @column_totals[ key ] ||= 0
            end
            do_column(w, key)
          end

        when 2
          # Audit
          [12].each do |k|
            key = key_from_worklog(w,k).to_s
            unless @column_headers[ key ]
              @column_headers[ key ] = name_from_worklog( w, k )
              @column_totals[ key ] ||= 0
            end
            do_column(w, key)
          end 
        when TIMESHEET
          # Time sheet
          columns = [ 16, 17, 18, 21, 19 ]
          w.available_custom_attributes.each do |ca|
            columns << "ca_#{ ca.id }"
          end
          columns << 22

          columns.each do |k|
            key = key_from_worklog(w, k)
            unless @column_headers[ key ]
              @column_headers[ key ] = name_from_worklog( w, k )
              @column_totals[ key ] ||= 0
            end
            do_column(w, key)
          end

        end

      end

    end

    csv = create_csv if @column_headers && @column_headers.size > 1
    unless csv.nil? || csv.empty?
      @generated_report = GeneratedReport.new
      @generated_report.company = current_user.company
      @generated_report.user = current_user
      @generated_report.filename = "clockingit_report.csv"
      @generated_report.report = csv
      @generated_report.save
    else
      flash['notice'] = _("Empty report, log more work!") if params[:report]
    end

  end

  def get_csv
    @report = GeneratedReport.find(params[:id], :conditions => ["user_id = ? AND company_id = ?", current_user.id, current_user.company_id])
    if @report
      send_data(@report.report,
                :type => 'text/csv; charset=utf-8; header=present',
                :filename => @report.filename)
    else
      redirect_to :action => 'list'
    end

  end

  def get_projects
    if params[:client_id].to_i == 0
      @projects = (current_user.projects.find(:all, :order => 'name').collect {|p| "{\"text\":\"#{(p.name + " / " + p.customer.name).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" } +
        current_user.completed_projects.find(:all, :order => 'name').collect {|p| "{\"text\":\"#{(p.name + " / " + p.customer.name + " - " + _('Completed')).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" }).join(',')
    else
      @projects = (current_user.projects.find(:all, :order => 'name' , :conditions => ["projects.customer_id = ?", params[:client_id] ]).collect {|p| "{\"text\":\"#{p.name.gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" } +
                   current_user.completed_projects.find(:all, :order => 'name' , :conditions => ["projects.customer_id = ?", params[:client_id] ]).collect {|p| "{\"text\":\"#{(p.name + " - " + _('Completed')).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" }
                   ).join(',')
    end

    res = '{"options":[{"value":"0", "text":"' + _('[Active Projects]') + '"},{"value":"-1", "text":"' + _('[Any Project]') + '"},{"value":"-2", "text":"' + _('[Closed Projects]') + '"}'

    res << ", #{@projects}" unless @projects.nil? || @projects.empty?
    res << ']}'
    render :text => res
  end

  private

  def clean_value(value)
    res = value
    begin
      res = [value.gsub(/<[a-zA-Z\/][^>]*>/,'')]
    rescue
    end

    return res
  end

  def create_csv
    csv_string = ""
    if @column_headers
      csv_string = FasterCSV.generate( :col_sep => "," ) do |csv|

        header = [nil]
        @column_headers.sort.each do |key,value|
          next if key == '__'
          header << clean_value(value)
        end
        header << [_("Total")]
        csv << header

        @rows.sort.each do |key, value|
          row = []
          row << [ clean_value(value["__"]) ]
#          row << [value['__'].gsub(/<[a-zA-Z\/][^>]*>/,'')]
          @column_headers.sort.each do |k,v|
            next if k == '__'
            val = nil
            val = value[k]/60 if value[k] && value[k].is_a?(Fixnum)
            val = clean_value(value[k]) if val.nil? && value[k]
            row << [val]
          end
          row << [@row_totals[key]/60]
          csv << row
        end

        row = []
        row << [_('Total')]
        @column_headers.sort.each do |key,value|
          next if key == '__'
          val = nil
          val = @column_totals[key]/60 if @column_totals[key] > 0
          row << [val]
        end
        row << [@total/60]
        csv << row


      end
    end
    csv_string
  end

  ###
  # Does any extra filtering of the logs depending on 
  # params.
  ###
  def filter_logs_by_params(logs, params)
    report_params = params[:report] || {}

    hide_approved = report_params[:hide_approved].to_i > 0
    if @type == TIMESHEET and hide_approved
      logs = logs.select { |wl| !wl.approved? }
    end

    return logs
  end

  def custom_attribute_from_key(str)
    match = str.match(/ca_(\d+)/)
    if match
      return current_user.company.custom_attributes.detect do |ca|
        ca.id == match[1].to_i
      end
    end
  end

  def get_date_header(w)
    if [0,1,2].include? @range.to_i
      tz.utc_to_local(w.started_at).strftime_localized("%a <br/>%d/%m")
    elsif [3,4].include? @range.to_i
      if tz.utc_to_local(w.started_at).beginning_of_week.month != tz.utc_to_local(w.started_at).beginning_of_week.since(6.days).month
        if tz.utc_to_local(w.started_at).beginning_of_week.month == tz.utc_to_local(w.started_at).month
          "#{_('Week')} #{tz.utc_to_local(w.started_at).strftime_localized("%W").to_i + 1} <br/>" +  tz.utc_to_local(w.started_at).beginning_of_week.strftime_localized("%d/%m") + ' - ' + tz.utc_to_local(w.started_at).end_of_month.strftime_localized("%d/%m")
        else
          "#{_('Week')} #{tz.utc_to_local(w.started_at).strftime_localized("%W").to_i + 1} <br/>" +  tz.utc_to_local(w.started_at).beginning_of_month.strftime_localized("%d/%m") + ' - ' + tz.utc_to_local(w.started_at).beginning_of_week.since(6.days).strftime_localized("%d/%m")
        end
      else
        "#{_('Week')} #{tz.utc_to_local(w.started_at).strftime_localized("%W").to_i + 1} <br/>" +  tz.utc_to_local(w.started_at).beginning_of_week.strftime_localized("%d/%m") + ' - ' + tz.utc_to_local(w.started_at).beginning_of_week.since(6.days).strftime_localized("%d/%m")
      end
    elsif @range.to_i == 5 || @range.to_i == 6
      tz.utc_to_local(w.started_at).strftime_localized("%b <br/>%y")
    end
  end

  def get_date_key(w)
    if [0,1,2].include? @range.to_i
      "#{tz.utc_to_local(w.started_at).to_date.year} #{tz.utc_to_local(w.started_at).to_date.strftime_localized('%u')}"
    elsif [3,4].include? @range.to_i
      "#{tz.utc_to_local(w.started_at).to_date.year} #{tz.utc_to_local(w.started_at).to_date.strftime_localized('%V')}"
    elsif @range.to_i == 5 || @range.to_i == 6
      "#{tz.utc_to_local(w.started_at).to_date.year} #{tz.utc_to_local(w.started_at).to_date.strftime_localized('%m')}"
    end
  end

  def key_from_worklog(w, r)
    if r == 1
      "#{w.customer.name} #{w.project.name} #{w.task.name} #{w.task.task_num}"
    elsif r == 2
      w.is_a?(Tag) ? w.id : 0
    elsif r == 3
      w.user_id
    elsif r == 4
      w.customer_id
    elsif r == 5
      w.project_id
    elsif r == 6
      w.task.milestone.nil? ? 0 : w.task.milestone.name
    elsif r == 7
      get_date_key(w)
    elsif r == 8
      w.task.status
    elsif r == 12
      "comment"
    elsif r == 13
      "#{tz.utc_to_local(w.started_at).strftime("%Y-%m-%d %H:%M")}"
    elsif r == 14
      tz.utc_to_local(w.started_at) + w.duration
    elsif r == 15
      if w.body && !w.body.empty?
        "#{w.customer.name}_#{w.project.name}_#{w.task.name}_#{w.id}"
      else
        "#{w.customer.name}_#{w.project.name}_#{w.task.name}"
      end
    elsif r == 16
      "1_start"
    elsif r == 17
      "2_end"
    elsif r == 18
      "3_task"
    elsif r == 19
      "5_note"
    elsif r == 20
      "#{w.task.requested_by}"
    elsif r == 21
      "4_user"
    elsif r == 22
      "6_approved"
    elsif (property = Property.find_by_filter_name(current_user.company, r))
      w.task.property_value(property)
    elsif (match = r.match(/ca_(\d+)/))
      r
    end
  end

  def name_from_worklog(w,r)
    if r == 1
      "#{w.task.issue_num} <a href=\"/tasks/view/#{w.task.task_num}\">#{w.task.name}</a> <br /><small>#{w.task.full_name}</small>"
    elsif r == 2
      w.is_a?(Tag) ? "#{w.name}" : "none"
    elsif r == 3
      "#{w.user ? w.user.name : _("Unassigned")}"
    elsif r == 4
      "#{w.customer.name}"
    elsif r == 5
      "#{w.project.full_name}"
    elsif r == 6
      w.task.milestone.nil? ? "none" : "#{w.task.milestone.name}"
    elsif r == 7
      get_date_header(w)
    elsif r == 8
      "#{w.task.status_type}"
    elsif r == 12
      _("Notes")
    elsif r == 13
      _("Start")
    elsif r == 14
      _("End")
    elsif r == 15
      "#{tz.utc_to_local(w.started_at).strftime_localized( "%a " + current_user.date_format )}"
    elsif r == 16
      _("Start")
    elsif r == 17
      _("End")
    elsif r == 18
      _("Task")
    elsif r == 19
      _("Note")
    elsif r == 20
      "#{w.task.requested_by}"
    elsif r == 21
      _("User")
    elsif r == 22
      _("Approved")
    elsif (property = Property.find_by_filter_name(current_user.company, r))
      w.task.property_value(property)
    elsif (match = r.match(/ca_(\d+)/))
      w.company.custom_attributes.find(match[1]).display_name
    end

  end


  def do_row(rkey, rname, vkey, duration)
    unless @rows[rkey]
      @rows[ rkey ] ||= { }
      @row_totals[rkey] ||= 0
      @rows[ rkey ]['__'] = rname
    end
    if duration.is_a? Fixnum
      @rows[rkey][vkey] ||= 0 
      @rows[rkey][vkey] += duration if duration
    else 
      @rows[rkey][vkey] ||= ""
      @rows[rkey][vkey] += "<br/>" if @rows[rkey][vkey].length > 0 && duration
      @rows[rkey][vkey] += "<br/>" if @rows[rkey][vkey].length > 0 && duration && !(duration.include?('#') || duration.include?('small'))
      @rows[rkey][vkey] += duration if duration
    end 
  end


  def do_column(w, key)
    logger.info("#{ key } - #{w.task_id} ##{w.task.task_num} || #{w.duration.to_i}")

    @column_totals[ key ] += w.duration unless ["comment", "1_start", "2_end", "3_task", "4_note"].include?(key)

    if @row_value == 2 && !w.task.tags.empty? && (@type == 1 || @type == 4)
      w.task.tags.each do |tag|
        rkey = key_from_worklog(tag, @row_value).to_s
        row_name = name_from_worklog(tag, @row_value)
        do_row(rkey, row_name, key, w.duration)
        @row_totals[rkey] += w.duration
      end

    elsif key == "comment"
      rkey = key_from_worklog(w, 15).to_s
      row_name = name_from_worklog(w, 1)
      body = w.body
      body.gsub!(/\n/, " <br/>") if body
      do_row(rkey, row_name, key, body)
      @row_totals[rkey] += w.duration
    elsif key == "1_start"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, "<a href=\"/tasks/edit_log/#{w.id}\">#{tz.utc_to_local(w.started_at).strftime_localized(current_user.time_format)}</a>")
      @row_totals[rkey] += w.duration
    elsif key == "2_end"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, "#{(tz.utc_to_local(w.started_at) + w.duration).strftime_localized(current_user.time_format)}")
    elsif key == "3_task"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, "#{w.task.issue_num} <a href=\"/tasks/view/#{w.task.task_num}\">#{w.task.name}</a> <br/><small>#{w.task.full_name}</small>")
    elsif key == "4_user"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, w.user.name)
    elsif key == "5_note"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      body = w.body
      body.gsub!(/\n/, " <br/>") if body
      do_row(rkey, row_name, key, body)
    elsif key == "6_approved"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      body = w.approved? ? _("Yes") : _("No")
      if current_user.can_approve_work_logs?
        body = "<input type='checkbox' #{ w.approved? ? "checked" : "" }"
        body += " onClick='toggleWorkLogApproval(this, #{ w.id })' />"
      end
      do_row(rkey, row_name, key, body)
    elsif (attr = custom_attribute_from_key(key))
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      value = w.values_for(attr).join(", ")
      do_row(rkey, row_name, key, value)
    else
      rkey = key_from_worklog(w, @row_value).to_s
      row_name = name_from_worklog(w, @row_value)
      do_row(rkey, row_name, key, w.duration)
      @row_totals[rkey] += w.duration
    end
  end


end
