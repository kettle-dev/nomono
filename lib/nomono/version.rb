# frozen_string_literal: true

module Nomono
  module Version
    VERSION = "1.0.5"

    module_function

    def gem_version
      Gem::Version.new(VERSION)
    end

    def major
      gem_version.segments[0]
    end

    def minor
      gem_version.segments[1]
    end

    def patch
      gem_version.segments[2]
    end

    def pre
      return nil unless gem_version.prerelease?

      gem_version.segments[3..].join(".")
    end

    def to_h
      {
        major: major,
        minor: minor,
        patch: patch,
        pre: pre
      }
    end

    def to_a
      to_h.values
    end
  end
  VERSION = Version::VERSION # Traditional Constant Location
end
