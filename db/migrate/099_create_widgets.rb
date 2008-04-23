class CreateWidgets < ActiveRecord::Migration
  def self.up
    create_table :widgets do |t|
      t.integer  :company_id
      t.integer  :user_id
      t.string   :name
      t.integer  :widget_type, :default => 0
      t.integer  :number, :default => 5
      t.string   :order_by
      t.string   :group_by
      t.string   :filter_by
      t.boolean  :collapsed, :default => false
      t.integer  :column, :default => 0
      t.integer  :position, :default => 0

      t.timestamps
    end

    say_with_time "Creating initial widgets for users.. " do 
      User.find(:all).each do |u|
        w = Widget.new
        w.user = u
        w.company_id = u.company_id
        w.name =  "Top Tasks"
        w.widget_type = 0
        w.number = 5
        w.order_by = "priority"
        w.collapsed = 0
        w.column = 0
        w.position = 0
        w.save

        w = Widget.new
        w.user = u
        w.company_id = u.company_id
        w.name =  "Newest Tasks"
        w.widget_type = 0
        w.number = 5
        w.order_by = "date"
        w.collapsed = 0
        w.column = 0
        w.position = 1
        w.save

        w = Widget.new
        w.user = u
        w.company_id = u.company_id
        w.name =  "Recent Activities"
        w.widget_type = 2
        w.number = 20
        w.collapsed = 0
        w.column = 2
        w.position = 0
        w.save

        w = Widget.new
        w.user = u
        w.company_id = u.company_id
        w.name =  "Projects"
        w.widget_type = 1
        w.number = 0
        w.collapsed = 0
        w.column = 1
        w.position = 0
        w.save
      end
    end
    
    add_index :widgets, :company_id
    add_index :widgets, :user_id
  end

  def self.down
    drop_table :widgets
  end
end
