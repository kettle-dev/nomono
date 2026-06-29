# frozen_string_literal: true

# This gem
require "version_gem"

require_relative "nomono/version"
require_relative "nomono/core"

Nomono::Version.class_eval do
  extend VersionGem::Basic
end
