class ProjectFolder < ActiveRecord::Base
  acts_as_tree :order => 'created_at'

  belongs_to :project
  has_many   :project_files, :dependent => :destroy

  before_destroy { |r|
    r.children.each do |f|
      f.destroy
    end
  }

  def total_files
    total = 0
    total += project_files.size
    self.children.each do |f|
      total += f.total_files
    end
    total
  end

  def num_files
    self.project_files.size
  end

  def num_folders
    self.children.size
  end

  def total_size
    total = 0
    project_files.each do |f|
      total += f.file_size unless f.file_size.nil?
    end
    self.children.each do |f|
      total += f.total_size
    end
    total
  end

  def full_path
    self.parent ? "#{self.parent.full_path}/#{self.name}" : (self.name == '/' ? self.name : "/#{self.name}")
  end

end
