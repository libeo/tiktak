class Task
  module Template

    def included(klass)
      klass.instance_eval do
        klass.include InstanceMethods
        klass.extend ClassMethods
    end

    module ClassMethods

    end

    module InstanceMethods

    end
    
  end

end
