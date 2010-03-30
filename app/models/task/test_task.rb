class Task
  module TestTask

    def self.included(klass)
      klass.instance_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module ClassMethods
      def test1
        'test'
      end
    end

    module InstanceMethods
      def test2
        'test'
      end
    end
    
  end

end
