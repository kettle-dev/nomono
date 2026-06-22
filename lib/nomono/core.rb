# frozen_string_literal: true

require_relative "resolver"
require_relative "dsl"

module Nomono
  class Error < StandardError; end

  module_function

  def resolver
    Resolver.new
  end

  def install!(dsl_class = nil)
    dsl_class ||= Bundler::Dsl if defined?(Bundler::Dsl)
    return false unless dsl_class

    dsl_class.include(GemfileDsl) unless dsl_class < GemfileDsl
    true
  end
end
