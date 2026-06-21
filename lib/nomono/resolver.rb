# frozen_string_literal: true

module Nomono
  class Resolver
    VALIDATOR = /^[a-z0-9][a-z0-9\-_]*$/
    FALSE_VALUES = %w[false 0 no off].freeze
    TRUE_VALUES = %w[true 1 yes on].freeze

    def initialize(env: ENV, home: nil)
      @env = env
      @home = home || env["HOME"] || Dir.home
    end

    def gems(gems:, prefix: "NOMONO_GEMS", allowlist: gems, path_env: nil, vendored_gems_env: nil, vendor_gem_dir_env: nil,
      debug_env: nil, root: ["src", "my"], strict: true)
      requested = normalize_gems(gems)
      allowed = normalize_gems(allowlist)
      requested.each { |gem_name| validate_gem_name!(gem_name, allowed, strict: strict) }

      path_key = path_env || "#{prefix}_DEV"
      base_path_value = fetch_with_fallback(path_key, "false")
      return {} if false_value?(base_path_value)

      dev_root = resolve_dev_root(base_path_value, root: root)
      vendored = parse_vendored(fetch_with_fallback(vendored_gems_env || "#{prefix}_VENDORED_GEMS", "", "VENDORED_GEMS"), allowed)
      vendor_dir_value = fetch_with_fallback(vendor_gem_dir_env || "#{prefix}_VENDOR_GEM_DIR", File.join(dev_root, "vendor"), "VENDOR_GEM_DIR")
      vendor_dir = absolutize(vendor_dir_value)

      gem_paths = requested.each_with_object({}) do |gem_name, memo|
        base = vendored.include?(gem_name) ? vendor_dir : dev_root
        memo[gem_name] = File.join(base, gem_name)
      end

      debug_key = debug_env || "#{prefix}_DEBUG"
      if true_value?(fetch_with_fallback(debug_key, "false", "KETTLE_DEV_DEBUG"))
        puts "Nomono gem_paths: #{gem_paths.inspect}"
      end

      gem_paths
    end

    private

    attr_reader :env, :home

    def normalize_gems(gem_names)
      Array(gem_names).map(&:to_s).map(&:strip).reject(&:empty?)
    end

    def validate_gem_name!(gem_name, allowed, strict:)
      raise Error, "gem names must match #{VALIDATOR}" unless gem_name.match?(VALIDATOR)
      return if allowed.include?(gem_name)
      return unless strict

      raise Error, "gem '#{gem_name}' is not allowlisted"
    end

    def resolve_dev_root(value, root:)
      val = value.to_s
      return join_home(*Array(root)) if true_value?(val)

      absolutize(val)
    end

    def parse_vendored(value, allowed)
      normalize_gems(value.to_s.split(",")).select do |gem_name|
        gem_name.match?(VALIDATOR) && allowed.include?(gem_name)
      end
    end

    def fetch_with_fallback(primary_key, default, legacy_key = nil)
      primary = env[primary_key]
      return primary unless primary.nil? || primary.empty?

      unless legacy_key.nil?
        legacy = env[legacy_key]
        return legacy unless legacy.nil? || legacy.empty?
      end

      default
    end

    def absolutize(path)
      return path if path.start_with?("/")

      join_home(path)
    end

    def join_home(*segments)
      File.join(home, *segments)
    end

    def true_value?(value)
      TRUE_VALUES.include?(value.to_s.downcase)
    end

    def false_value?(value)
      FALSE_VALUES.include?(value.to_s.downcase)
    end
  end
end
