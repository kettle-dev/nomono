# frozen_string_literal: true

module Nomono
  module GemfileDsl
    def nomono_gems(gems:, **opts)
      Nomono.resolver.gems(gems: gems, **opts)
    end

    # Version requirements are supplied by the caller's template facts, not
    # inferred from checkout versions. Omitted entries retain the legacy >= 0
    # declaration; repository shape and ENV selection remain caller policy.
    def eval_nomono_gems(gems:, requirements: {}, **opts)
      nomono_gems(gems: gems, **opts).each do |gem_name, gem_path|
        gem(gem_name, *Array(requirements[gem_name]), path: gem_path)
      end
    end
  end
end
