require 'active_support/core_ext/module/inclusion'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/attr_internal'
require 'active_support/core_ext/module/attr_accessor_with_default'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/introspection'
require 'active_support/core_ext/module/loading'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/module/model_naming'

class Module
  include ActiveSupport::CoreExt::Module::ModelNaming
end
