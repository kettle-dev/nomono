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
      debug_env: nil, path_aliases: nil, path_aliases_env: nil, root: ["src", "my"], strict: true, **_options)
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
      aliases = normalize_path_aliases(
        path_aliases || fetch_with_fallback(path_aliases_env || "#{prefix}_PATH_ALIASES", "", "NOMONO_PATH_ALIASES")
      )

      gem_paths = requested.each_with_object({}) do |gem_name, memo|
        base = vendored.include?(gem_name) ? vendor_dir : dev_root
        memo[gem_name] = normalize_path_alias(File.join(base, gem_name), aliases)
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

    def normalize_path_aliases(value)
      aliases = case value
      when nil
        []
      when Hash
        value.map { |source, canonical| [source.to_s, canonical.to_s] }
      when Array
        value.map do |entry|
          unless entry.respond_to?(:to_ary) && entry.to_ary.size == 2
            raise Error, "path aliases must be configured as source=canonical pairs"
          end

          entry.to_ary.map(&:to_s)
        end
      else
        value.to_s.split(",").map do |entry|
          next if entry.strip.empty?

          source, canonical = entry.split("=", 2).map { |part| part.to_s.strip }
          [source, canonical]
        end.compact
      end

      aliases.map do |source, canonical|
        validate_path_alias!(source, canonical)
        [strip_trailing_slash(source), strip_trailing_slash(canonical)]
      end.sort_by { |source, _canonical| -source.length }
    end

    def validate_path_alias!(source, canonical)
      if source.to_s.empty? || canonical.to_s.empty?
        raise Error, "path aliases must be configured as source=canonical pairs"
      end
      unless source.start_with?("/") && canonical.start_with?("/")
        raise Error, "path aliases must use absolute paths"
      end
      return if File.realpath(source) == File.realpath(canonical)

      raise Error, "path alias #{source}=#{canonical} does not resolve to the same directory"
    rescue SystemCallError => e
      raise Error, "path alias #{source}=#{canonical} cannot be verified: #{e.message}"
    end

    def normalize_path_alias(path, aliases)
      aliases.each do |source, canonical|
        next unless path == source || path.start_with?("#{source}/")

        return "#{canonical}#{path.delete_prefix(source)}"
      end

      path
    end

    def strip_trailing_slash(path)
      path = path.dup
      path.chop! while path.end_with?("/")
      path
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
