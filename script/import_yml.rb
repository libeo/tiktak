puts "Loading rails environment..."
ENV['RAILS_ENV'] = 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rubygems'
require 'yaml'
puts "env loaded"

SEP = '--'

raise "No .yml file specified !" if ARGV.first == nil or (ARGV.first and !(ARGV.first =~ /\.yml$/))

puts "Loading YAML..."
yml = YAML::load_file(ARGV.first)
user = User.find_by_username yml.delete('Utilisateur')
customer = Customer.find_by_name yml.delete('Client')
project = customer.projects.find(:first, :conditions => {:name => yml.delete('Projet')})

puts "Importing..."
yml.each do |milestone_str, lines|
  milestone = project.milestones.find(:first, :conditions => {:name => milestone_str})
  raise "Milestone #{milestone_str} does not exist" unless milestone
  lines.each do |line|
    parts = line.split(SEP)
    duration_str = parts.pop.strip
    task_name = parts.join(SEP).strip
    duration = TimeParser.parse_time(user, duration_str, true)
    task = Task.create_for_user(user, project, {:milestone => milestone, :name => task_name, :duration => duration})
    task.save
    puts "created #{task}"
  end
end
