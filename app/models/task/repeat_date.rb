class Task
  # Module that regroups all functions dealing with operations on repeating tasks. 
  # A repeating task represents a task that is created on a regular basis. 
  # For example : Team meeting every first monday of the week.
  # The 'repeat' field represents how much time has to pass before repeating a task.
  # The functions in this module help to transform the repeat schedule into a human-readable form.
  module RepeatDate
    augmentation do

      REPEAT_DATE = [
        [_('last')],
        ['1st', 'first'], ['2nd', 'second'], ['3rd', 'third'], ['4th', 'fourth'], ['5th', 'fifth'], ['6th', 'sixth'], ['7th', 'seventh'], ['8th', 'eighth'], ['9th', 'ninth'], ['10th', 'tenth'],
        ['11th', 'eleventh'], ['12th', 'twelwth'], ['13th', 'thirteenth'], ['14th', 'fourteenth'], ['15th', 'fifthteenth'], ['16th', 'sixteenth'], ['17th', 'seventeenth'], ['18th', 'eighthteenth'], ['19th', 'nineteenth'], ['20th', 'twentieth'],
        ['21st', 'twentyfirst'], ['22nd', 'twentysecond'], ['23rd', 'twentythird'], ['24th', 'twentyfourth'], ['25th', 'twentyfifth'], ['26th', 'twentysixth'], ['27th', 'twentyseventh'], ['28th', 'twentyeight'], ['29th', 'twentyninth'], ['30th', 'thirtieth'], ['31st', 'thirtyfirst'],

      ]
    
      # Creates a clone of the current task to be used when creating repeated tasks
      def repeat_task(repeat_string)
        task = self.clone
        task.status = 0
        task.project_id = self.project_id
        task.company_id = self.company_id
        task.creator_id = self.creator_id
        task.set_tags(self.tags.collect{|t| t.name}.join(', '))
        task.set_self_num(self.company_id)
        task.milestone_id = self.milestone_id
        task.due_at = task.next_repeat_date

        task.save
        task.reload

        self.assignments.each do |a|
          att = a.attributes
          att.delete :id
          att.delete :task_id
          task.assignments.create(att)
        end

        self.dependencies.each do |d|
          task.dependencies << d
        end

        task.save
      end
      

      # Creates a textual representation of the next scheduled repeat date. Returns a blank string if there is no repeat date.
      # Examples :
      # w: 1, next day-of-week: Every _Sunday_
      # m: 1, next day-of-month: On the _10th_ day of every month
      # n: 2, nth day-of-week: On the _1st_ _Sunday_ of each month
      # y: 2, day-of-year: On _1_/_20_ of each year (mm/dd)
      # a: 1, add-days: _14_ days after each time the task is completed

      def next_repeat_date
        @date = nil

        return nil if self.repeat.nil?

        args = self.repeat.split(':')
        code = args[0]

        @start = self.due_at
        @start ||= Time.now.utc

        case code
        when ''  :
        when 'w' :
          @date = @start + (7 - @start.wday + args[1].to_i).days
        when 'm' :
          @date = @start.beginning_of_month.next_month.change(:day => (args[1].to_i))
        when 'n' :
          @date = @start.beginning_of_month.next_month.change(:day => 1)
          if args[2].to_i < @date.day
            args[2] = args[2].to_i + 7
          end
          @date = @date + (@date.day + args[2].to_i - @date.wday - 1).days
          @date = @date + (7 * (args[1].to_i - 1)).days
        when 'l' :
          @date = @start.next_month.end_of_month
          if args[1].to_i > @date.wday
            @date = @date.change(:day => @date.day - 7)
          end
          @date = @date.change(:day => @date.day - @date.wday + args[1].to_i)
        when 'y' :
          @date = @start.beginning_of_year.change(:year => @start.year + 1, :month => args[1].to_i, :day => args[2].to_i)
        when 'a' :
          @date = @start + args[1].to_i.days
        end
        @date.change(:hour => 23, :min => 59)
      end


      # Returns a string representing the frequency at which the task must be repeated. Returns a blank string if there is no repeat date.
      # Examples :
      # every 1st day
      # every 2nd month
      # every 3rd year
      # every 4th week
      def repeat_summary
        return "" if self.repeat.nil?

        args = self.repeat.split(':')
        code = args[0]

        case code
        when ''
        when 'w'
          "#{_'every'} #{_(Date::DAYNAMES[args[1].to_i]).downcase}"
        when 'm'
          "#{_'every'} #{REPEAT_DATE[args[1].to_i][0]}"
        when 'n'
          "#{_'every'} #{REPEAT_DATE[args[1].to_i][0]} #{_(Date::DAYNAMES[args[2].to_i]).downcase}"
        when 'l'
          "#{_'every'} #{_'last'} #{_(Date::DAYNAMES[args[2].to_i]).downcase}"
        when 'y'
          "#{_'every'} #{args[1].to_i}/#{args[2].to_i}"
        when 'a'
          "#{_'every'} #{args[1]} #{_ 'days'}"
        end
      end

      # Parses a textual representation of a repeat frequency (e.g every 1st week) into a a string representing the repeat parameters seperated by a column (e.g "every:1:week")
      # TODO: confirm that the description si really the right format
      def parse_repeat(r)
        # every monday
        # every 15th

        # every last monday

        # every 3rd tuesday
        # every 1st may
        # every 12 days

        r = r.strip.downcase

        return unless r[0..(-1 + (_('every') + " ").length)] == _('every') + " "

        tokens = r[((_('every') + " ").length)..-1].split(' ')

        mode = ""
        args = []

        if tokens.size == 1

          if tokens[0] == _('day')
            # every day
            mode = "a"
            args[0] = '1'
          end

          if mode == ""
            # every friday
            0.upto(Date::DAYNAMES.size - 1) do |d|
              if Date::DAYNAMES[d].downcase == tokens[0]
                mode = "w"
                args[0] = d
                break
              end
            end
          end

          if mode == ""
            #every 15th
            1.upto(REPEAT_DATE.size - 1) do |i|
              if REPEAT_DATE[i].include? tokens[0]
                mode = 'm'
                args[0] = i
                break
              end
            end
          end

        elsif tokens.size == 2

          # every 2nd wednesday
          0.upto(Date::DAYNAMES.size - 1) do |d|
            if Date::DAYNAMES[d].downcase == tokens[1]
              1.upto(REPEAT_DATE.size - 1) do |i|
                if REPEAT_DATE[i].include? tokens[0]
                  mode = 'n'
                  args[0] = i
                  args[1] = d
                  break;
                end
              end
            end
          end

          if mode == ""
            # every 14 days
            if tokens[1] == _('days')
              mode = 'a'
              args[0] = tokens[0].to_i
            end
          end

          if mode == ""
            if tokens[0] == _('last')
              0.upto(Date::DAYNAMES.size - 1) do |d|
                if Date::DAYNAMES[d].downcase == tokens[1]
                  mode = 'l'
                  args[0] = d
                  break
                end
              end
            end
          end

          if mode == ""
            # every may 15th / every 15th of may

          end

        end
        if mode != ""
          "#{mode}:#{args.join ':'}"
        else
          ""
        end
      end
      
    end

  end

end
