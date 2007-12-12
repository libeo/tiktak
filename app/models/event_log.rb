class EventLog < ActiveRecord::Base
  belongs_to :target, :polymorphic => true

  TASK_CREATED       = 1
  TASK_COMPLETED     = 2
  TASK_REVERTED      = 3
  TASK_DELETED       = 4
  TASK_MODIFIED      = 5
  TASK_COMMENT       = 6
  TASK_WORK_ADDED    = 7
  TASK_ASSIGNED      = 8
  TASK_ARCHIVED      = 9
  TASK_RESTORED      = 14

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

end
