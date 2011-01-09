puts "Loading rails environment..."
ENV['RAILS_ENV'] = 'production'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rubygems'

puts "Enter company name : "
company = gets.chomp
puts "Enter subdomain : "
subdomain = gets.chomp
puts "Enter admin name : "
name = gets.chomp
puts "Enter username : "
username = gets.chomp
puts "Enter password : "
password = gets.chomp
puts "Enter email : "
email = gets.chomp

@user = User.new
@company = Company.new

@user.name = name
@user.username = username
@user.password = password
@user.email = email
@user.time_zone = "Europe/Oslo"
@user.locale = "en_US"
@user.option_externalclients = 1
@user.option_tracktime = 1
@user.option_tooltips = 1
@user.date_format = "%d/%m/%Y"
@user.time_format = "%H:%M"
@user.admin = 1


puts "  Creating initial company..."

@company.name = company
@company.contact_email = email
@company.contact_name = name
@company.subdomain = subdomain.downcase
@company.payperiod_date = Date.today

if @company.save
  @customer = Customer.new
  @customer.name = @company.name

  @company.customers << @customer
  puts "  Creating initial user..."
  @company.users << @user
else
  puts "Error trying to create company. searching for existing company"
  puts @company.errors.full_messages
  c = Company.find_by_subdomain(subdomain)
  if c
    puts "** Unable to create initial company, #{subdomain} already registered.. **"

    del = "\n"
    print "Delete existing company '#{c.name}' with subdomain '#{subdomain}' and try again? [y]: "
    del = gets
    del = "y" if del == "\n"
    del.strip!
    if del.downcase.include?('y')
      c.destroy
      if @company.save
        @customer = Customer.new
        @customer.name = @company.name

        @company.customers << @customer
        puts "  Creating initial user..."
        @company.users << @user

      else
        puts " Still unable to create initial company. Check database settings..."
        exit
      end
    end

  else
    puts "Could not create company and no existing company found. This should not happen. exiting"
    exit
  end
end

unless @user.save
  puts "Error during user creation !"
end
