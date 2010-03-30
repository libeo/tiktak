class Task
  module Tags
    augmentation do

      ########################CLASS METHODS#################################

      # { :clockingit => [ {:tasks => []} ] }

      def self.filter_by_tag(tag, tasks)
        matching = []
        tasks.each do | t |
          if t.has_tag? tag
            matching += [t]
          end
        end
        matching
      end

      def self.group_by_tags(tasks, tags, done_tags, depth)
        groups = { }

        tags -= done_tags
        tags.each do |tag|

          done_tags += [tag]


          unless tasks.nil?  || tasks.size == 0

            matching_tasks = Task.filter_by_tag(tag,tasks)
            unless matching_tasks.nil? || matching_tasks.size == 0
              tasks -= matching_tasks
              groups[tag] = Task.group_by_tags(matching_tasks, tags, done_tags, depth+1)
            end


          end

          done_tags -= [tag]

        end
        if groups.keys.size > 0 && !tasks.nil? && tasks.size > 0
          [tasks, groups]
        elsif groups.keys.size > 0
          [groups]
        else
          [tasks]
        end
      end

      def self.tag_groups(company_id, tags, tasks)
        Task.group_by_tags(tasks,tags,[], 0)
      end

      def Task.tagged_with(tag, options = {})
        tags = []
        if tag.is_a? Tag
          tags = [tag.name]
        elsif tag.is_a? String
          tags = tag.include?(",") ? tag.split(',') : [tag]
        elsif tag.is_a? Array
          tags = tag
        end

        task_ids = ''
        if options[:filter_user].to_i > 0
          task_ids = User.find(options[:filter_user].to_i).tasks.collect { |t| t.id }.join(',')
        end

        if options[:filter_user].to_i < 0
          task_ids = Task.find(:all, :select => "tasks.*", :joins => "LEFT OUTER JOIN task_owners t_o ON tasks.id = t_o.task_id", :conditions => ["tasks.company_id = ? AND t_o.id IS NULL", options[:company_id]]).collect { |t| t.id }.join(',')
        end

        completed_milestones_ids = Milestone.find(:all, :conditions => ["company_id = ? AND completed_at IS NOT NULL", options[:company_id]]).collect{ |m| m.id}.join(',')

        task_ids_str = "tasks.id IN (#{task_ids})" if task_ids != ''
        task_ids_str = "tasks.id = 0" if task_ids == ''

        sql = "SELECT tasks.* FROM (tasks, task_tags, tags) LEFT OUTER JOIN milestones ON milestones.id = tasks.milestone_id  LEFT OUTER JOIN projects ON projects.id = tasks.project_id WHERE task_tags.tag_id=tags.id AND tasks.id = task_tags.task_id"
        sql << " AND (" + tags.collect { |t| sanitize_sql(["tags.name='%s'",t.downcase.strip]) }.join(" OR ") + ")"
        sql << " AND tasks.company_id=#{options[:company_id]}" if options[:company_id]
        sql << " AND tasks.project_id IN (#{options[:project_ids]})" if options[:project_ids]
        sql << " AND tasks.hidden = 1" if options[:filter_status].to_i == -2
        sql << " AND tasks.hidden = 0" if options[:filter_status].to_i != -2
        sql << " AND tasks.status = #{options[:filter_status]}" unless (options[:filter_status].to_i == -1 || options[:filter_status].to_i == 0 || options[:filter_status].to_i == -2)
        sql << " AND (tasks.status = 0 OR tasks.status = 1)" if options[:filter_status].to_i == 0
        sql << " AND #{task_ids_str}" unless options[:filter_user].to_i == 0
        sql << " AND tasks.milestone_id = #{options[:filter_milestone]}" if options[:filter_milestone].to_i > 0
        sql << " AND (tasks.milestone_id IS NULL OR tasks.milestone_id = 0)" if options[:filter_milestone].to_i < 0
        sql << " AND (tasks.milestone_id NOT IN (#{completed_milestones_ids}) OR tasks.milestone_id IS NULL)" if completed_milestones_ids != ''
        sql << " AND projects.customer_id = #{options[:filter_customer]}" if options[:filter_customer].to_i > 0
        sql << " GROUP BY tasks.id"
        sql << " HAVING COUNT(tasks.id) = #{tags.size}"
        sql << " ORDER BY tasks.completed_at is NOT NULL, tasks.completed_at DESC"
        sql << ", #{options[:sort]}" if options[:sort] && options[:sort].length > 0

        find_by_sql(sql)
      end
      

      ########################INSTACE METHODS#################################
      
      def set_tags( tagstring )
        return false unless tagstring
        self.tags.clear
        tagstring.split(',').each do |t|
          tag_name = t.downcase.strip

          if tag_name.length == 0
            next
          end

          tag = Company.find(self.company_id).tags.find_or_create_by_name(tag_name)
          self.tags << tag unless self.tags.include?(tag)
        end
        true
      end

      def set_tags=( tagstring )
        self.set_tags(tagstring)
      end

      def has_tag?(tag)
        name = tag.to_s
        self.tags.collect{|t| t.name}.include? name
      end
      
    end
  end
end
