module NoticeGroupsHelper
  include Misc
  def options_for_projects(selected = nil, projects = nil)
    s = nil
    unless selected.nil?
      if selected.is_a? Array
        selected.each do |se|
          s.push(se.id)
        end
      else
        s = selected
      end
    end
    projects = Project.find(:all, :include => "customer", :order => "customers.name, projects.name", :select => [:id, :name], :conditions => ["completed_at is null"]) unless projects

    last_customer = nil
    options = []

    projects.each do |project|
      if project.customer != last_customer
        options << [ h(project.customer.name), [] ]
        last_customer = project.customer
      end

      options.last[1] << [ project.name, project.id ]
    end

    return grouped_options_for_select(options, s)
  end

  def options_for_user_projects(selected = nil)
    return options_for_projects(selected, 
      Project.find(:all, :include => :customer, :order => "customers.name, projects.name", :select => [:id, :name],
        :conditions => "projects.id in (#{current_project_ids_query})")
    )
  end

end
