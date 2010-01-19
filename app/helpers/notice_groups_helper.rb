module NoticeGroupsHelper
  include Misc
  def options_for_projects(selected = nil)
    s = []
    unless selected.nil?
      selected.each do |se|
        s.push(se.id)
      end
    end
    puts s
    #selected.map!{ |s| s.id }
    projects = current_user.projects.find(:all, :include => "customer", :order => "customers.name, projects.name")

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
end
