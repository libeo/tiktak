# Wrapper for worklog entries, containing 
# WorkLog, WikiPage, ProjectFile, and Post types linking to
# the respective models of those types
# 

class EventLog < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :user
  belongs_to :company


  TASK_CREATED       = 1
  TASK_COMPLETED     = 2
  TASK_REVERTED      = 3
  TASK_DELETED       = 4
  TASK_MODIFIED      = 5
  TASK_COMMENT       = 6
  TASK_WORK_ADDED    = 7
  TASK_ASSIGNED      = 8
  TASK_ARCHIVED      = 9
  TASK_RESTORED      = 16

  PAGE_CREATED       = 10
  PAGE_DELETED       = 11
  PAGE_RENAMED       = 12
  PAGE_MODIFIED      = 13

  WIKI_CREATED       = 14
  WIKI_MODIFIED      = 15

  FILE_UPLOADED      = 20
  FILE_DELETED       = 21

  ACCESS_GRANTED     = 30
  ACCESS_REVOKED     = 31

  SCM_COMMIT         = 40

  PROJECT_COMPLETED   = 50
  MILESTONE_COMPLETED = 51
  PROJECT_REVERTED    = 52
  MILESTONE_REVERTED  = 53

  FORUM_NEW_POST      = 60

  RESOURCE_PASSWORD_REQUESTED = 70
  RESOURCE_CHANGE = 71

  EVENT_LABELS = {
    TASK_CREATED => 'Task created',
    TASK_COMPLETED  =>  'Task completed',
    TASK_REVERTED   =>  'Task reverted',
    TASK_DELETED    =>  'Task deleted',
    TASK_MODIFIED   =>  'Task modified',
    TASK_COMMENT    =>  'Task comment',
    TASK_WORK_ADDED =>  'Task work added',
    TASK_ASSIGNED   =>  'Task assigned',
    TASK_ARCHIVED   =>  'Task archived',
    TASK_RESTORED   =>  'Task restored',
    PAGE_CREATED => 'Page created',
    PAGE_DELETED  => 'Page deleted',
    PAGE_RENAMED  => 'Page renamed',
    PAGE_MODIFIED => 'Page modified',
    WIKI_CREATED   => 'Wiki created',
    WIKI_MODIFIED  => 'Wiki modified',
    FILE_UPLOADED  => 'File uploaded',
    FILE_DELETED   => 'File deleted',
    ACCESS_GRANTED => 'Access granted',
    ACCESS_REVOKED => 'Access revoked',
    SCM_COMMIT     => 'Scm commit',
    PROJECT_COMPLETED   => 'Project completed',
    MILESTONE_COMPLETED => 'Milestone completed',
    PROJECT_REVERTED    => 'Project reverted',
    MILESTONE_REVERTED  => 'Milestone reverted',
    FORUM_NEW_POST => 'Forum new post',
    RESOURCE_PASSWORD_REQUESTED => 'Resource password requested',
    RESOURCE_CHANGE => 'Resource change'
  }

  def started_at
    self.created_at
  end
  
end
