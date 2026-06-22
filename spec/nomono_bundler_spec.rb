# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe Nomono do
  it "does not install the Bundler DSL from the runtime entrypoint" do
    script = <<~RUBY
      require "bundler"
      require "nomono"
      raise "Bundler DSL unexpectedly installed" if Bundler::Dsl < Nomono::GemfileDsl
      raise "resolver missing" unless Nomono.resolver.is_a?(Nomono::Resolver)
    RUBY

    clean_env = {
      "BUNDLE_BIN_PATH" => nil,
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_LOCKFILE" => nil,
      "BUNDLER_SETUP" => nil,
      "BUNDLER_VERSION" => nil,
      "RUBYLIB" => nil,
      "RUBYOPT" => nil
    }
    stdout, stderr, status = Open3.capture3(
      clean_env,
      RbConfig.ruby,
      "-I#{File.expand_path("../lib", __dir__)}",
      "-e",
      script
    )

    expect(status).to be_success, "#{stdout}#{stderr}"
  end

  it "can be required after the runtime entrypoint" do
    expect(require("nomono/bundler")).to be(false).or be(true)
    expect(described_class.install!).to be(true)
  end

  it "installs the Bundler DSL without activating version_gem" do
    script = <<~RUBY
      require "bundler"
      require "nomono/bundler"
      raise "version_gem activated" if Gem.loaded_specs.key?("version_gem")
      raise "Bundler DSL not installed" unless Bundler::Dsl < Nomono::GemfileDsl
    RUBY

    clean_env = {
      "BUNDLE_BIN_PATH" => nil,
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_LOCKFILE" => nil,
      "BUNDLER_SETUP" => nil,
      "BUNDLER_VERSION" => nil,
      "RUBYLIB" => nil,
      "RUBYOPT" => nil
    }
    stdout, stderr, status = Open3.capture3(
      clean_env,
      RbConfig.ruby,
      "-I#{File.expand_path("../lib", __dir__)}",
      "-e",
      script
    )

    expect(status).to be_success, "#{stdout}#{stderr}"
  end
end
