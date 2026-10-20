# frozen_string_literal: true

module Nomono
  module GemfileDsl
    # Only source-related state is replaced. Dependency#dup retains effective
    # conditions and metadata, including fields unknown to this Bundler adapter.
    SOURCE_OPTIONS = %w[source path git github branch ref tag glob submodules name].freeze
    private_constant :SOURCE_OPTIONS

    # Activated on this DSL instance only, after an intentional local override.
    # Bundler 4 routes gemspec development dependencies through add_dependency;
    # Bundler 2 routes them through gem instead.
    module LocalDeclarations
      def gem(name, *args)
        return super if method(:add_dependency).super_method

        options = args.last.is_a?(Hash) ? args.last : {}
        nomono_declaration(name, options[:type] == :development || options["type"] == :development) { super }
      end

      def to_definition(*args)
        nomono_prune_displaced_sources
        super
      end

      private

      def add_dependency(name, version = nil, options = {})
        nomono_declaration(name, options["gemspec_dev_dep"]) { super }
      end
    end
    private_constant :LocalDeclarations

    def nomono_gems(gems:, **opts)
      Nomono.resolver.gems(gems: gems, **opts)
    end

    # Requirements are caller facts, not checkout versions. An existing direct
    # dependency keeps its constraints and metadata; explicit facts only narrow
    # them. A new dependency with no facts retains Bundler's default >= 0.
    def eval_nomono_gems(gems:, requirements: {}, **opts)
      # Bundler's plugin scan evaluates the whole Gemfile with a plugins-only
      # DSL: some Bundlers undef gem and gemspec, newer ones define gem as an
      # explicit no-op. Either way no dependency is collected, so there is no
      # declaration graph to override here.
      return if respond_to?(:dependencies) && nomono_plugin_scan_dsl?

      nomono_gems(gems: gems, **opts).each do |gem_name, gem_path|
        # Keep lightweight non-Bundler consumers of the macro working too.
        unless respond_to?(:dependencies)
          gem(gem_name, *Array(requirements[gem_name]), path: gem_path)
          next
        end

        constraints = Array(requirements[gem_name]) + nomono_gemspec_requirements(gem_name)
        current = dependencies.find { |dep| dep.name == gem_name }
        if current
          local_source = path(gem_path) {}
          replacement = nomono_local_dependency(current, local_source, gem_path, constraints)
          dependencies[dependencies.index(current)] = replacement
        else
          gem(gem_name, *Array(requirements[gem_name]), path: gem_path)
          replacement = dependencies.last
          # A plugins-only DSL silently drops the declaration; nothing was
          # collected, so there is no override to register.
          next unless replacement && replacement.name == gem_name
        end
        @nomono_overrides ||= {}
        previous = @nomono_overrides[gem_name]
        @nomono_overrides[gem_name] = {
          source: replacement.source,
          path: gem_path,
          declaration: previous ? previous[:declaration] : !current.nil?
        }
        singleton_class.prepend(LocalDeclarations) unless singleton_class < LocalDeclarations
      end
    end

    private

    # Both known plugins-only DSL shapes collect no gem declarations: older
    # Bundlers undef gem, and Bundler 4.1+ defines it as an explicit no-op.
    # The ancestor check is primary; the respond_to fallback covers any
    # plugin DSL that undef's gem instead.
    def nomono_plugin_scan_dsl?
      return true if defined?(Bundler::Plugin::DSL) && is_a?(Bundler::Plugin::DSL)

      !respond_to?(:gem)
    end

    # Bundler may already have preferred a direct Gemfile declaration and
    # discarded the intersected gemspec development constraint from its list.
    def nomono_gemspec_requirements(name)
      gemspecs.flat_map(&:development_dependencies).select { |dep| dep.name == name }.flat_map { |dep| dep.requirement.as_list }
    end

    # Let Bundler construct the later declaration normally, but in isolation so
    # its duplicate guard cannot discard a gemspec constraint or reject the
    # deliberate source override. Always restore the real list on failure.
    def nomono_declaration(name, gemspec_development)
      override = @nomono_overrides && @nomono_overrides[name]
      current = dependencies.find { |dep| dep.name == name }
      return yield unless override && current
      development = current.respond_to?(:gemspec_dev_dep?) ? current.gemspec_dev_dep? : current.type == :development
      return yield if override[:declaration] && !development && !gemspec_development

      original = @dependencies
      begin
        @dependencies = []
        yield
        incoming = @dependencies.fetch(0)
      ensure
        @dependencies = original
      end
      metadata = (gemspec_development && override[:declaration]) ? current : incoming
      constraints = current.requirement.as_list + incoming.requirement.as_list
      replacement = nomono_local_dependency(metadata, override[:source], override[:path], constraints)
      dependencies[dependencies.index(current)] = replacement
      override[:declaration] = true
    end

    # Defer cleanup until declarations are complete: an enclosing source block
    # can still declare other gems after the override. Unreferenced old git/path
    # sources otherwise participate in resolution and may require a checkout.
    def nomono_prune_displaced_sources
      Array(@nomono_displaced_sources).each do |source|
        next if source == @sources.default_source || dependencies.any? { |dep| dep.source == source }

        @sources.git_sources.delete(source)
        @sources.path_sources.delete(source)
        @sources.non_global_rubygems_sources.delete(source)
        @sources.plugin_sources.delete(source)
      end
    end

    def nomono_local_dependency(dependency, source, gem_path, requirements)
      replacement = dependency.dup
      replacement.instance_variable_set(:@requirement, Gem::Requirement.new(dependency.requirement.as_list + requirements))
      @nomono_displaced_sources ||= []
      @nomono_displaced_sources |= [dependency.source] if dependency.source && dependency.source != source
      (SOURCE_OPTIONS - ["name"]).each { |key| replacement.instance_variable_set(:"@#{key}", nil) }
      replacement.instance_variable_set(:@source, source)
      replacement.instance_variable_set(:@path, gem_path)
      # Bundler 4 lazily reads @options; older Bundlers store eager ivars.
      if (options = dependency.instance_variable_get(:@options))
        options = options.except(*SOURCE_OPTIONS)
        replacement.instance_variable_set(:@options, options.merge("source" => source, "path" => gem_path))
      end
      replacement
    end
  end
end
