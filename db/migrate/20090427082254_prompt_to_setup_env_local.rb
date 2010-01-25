class PromptToSetupEnvLocal < ActiveRecord::Migration
  def self.up
    file = "#{ RAILS_ROOT }/config/environment.local.rb"
    sample = "#{ RAILS_ROOT }/config/environment.local.example"

    if !File.exists?(file)
      File.copy(sample, file)
      puts ""
      puts "Please examine config/environment.local.rb and enter your local configuration"
      puts ""
    end
  end

  def self.down
  end
end
