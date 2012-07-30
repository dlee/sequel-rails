
module Sequel
  module Plugins
    # The RailsExtensions plugin adds a single class method to Sequel::Model in
    # order to emulate the behavior of ActiveRecord's `.find` method, where an
    # exception is raised if a record cannot be found by the given id. Here, we
    # raise a ModelNotFoundError, which is rescued in controllers like so:
    #
    #   config.action_dispatch.rescue_responses.merge!(
    #    'Sequel::Plugins::RailsExtensions::ModelNotFound' => :not_found
    #   )
    #
    module RailsExtensions
      class ModelNotFound < Sequel::Error; end

      module ClassMethods
        def find!(args)
          record = self[args]
          raise ModelNotFound, "Couldn't find #{self} matching #{args}." unless record
          return record
        end
      end
    end
  end
end
