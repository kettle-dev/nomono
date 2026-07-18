# frozen_string_literal: true

RSpec.describe Nomono::Resolver do
  subject(:resolver) { described_class.new(env: env, home: "/home/test") }

  let(:env) { {} }

  describe "#gems" do
    let(:gems) { %w[kettle-dev kettle-test kettle-soup-cover] }

    it "returns empty hash when local mode is disabled" do
      env["NOMONO_GEMS_DEV"] = "false"

      expect(resolver.gems(gems: gems)).to eq({})
    end

    it "returns empty hash when local mode is unset" do
      expect(resolver.gems(gems: gems)).to eq({})
    end

    it "resolves siblings from default root when local mode is enabled" do
      env["NOMONO_GEMS_DEV"] = "true"

      expect(resolver.gems(gems: gems)).to eq(
        "kettle-dev" => "/home/test/src/my/kettle-dev",
        "kettle-test" => "/home/test/src/my/kettle-test",
        "kettle-soup-cover" => "/home/test/src/my/kettle-soup-cover"
      )
    end

    it "supports vendored overrides with legacy env variable names" do
      env["NOMONO_GEMS_DEV"] = "/workspace/my"
      env["VENDORED_GEMS"] = "kettle-test"
      env["VENDOR_GEM_DIR"] = "/workspace/my/vendor"

      expect(resolver.gems(gems: gems)).to eq(
        "kettle-dev" => "/workspace/my/kettle-dev",
        "kettle-test" => "/workspace/my/vendor/kettle-test",
        "kettle-soup-cover" => "/workspace/my/kettle-soup-cover"
      )
    end

    it "ignores invalid and non-allowlisted vendored entries" do
      env["NOMONO_GEMS_DEV"] = "/workspace/my"
      env["VENDORED_GEMS"] = "kettle-test,../bad,kettle-devs"

      expect(resolver.gems(gems: gems)).to eq(
        "kettle-dev" => "/workspace/my/kettle-dev",
        "kettle-test" => "/workspace/my/vendor/kettle-test",
        "kettle-soup-cover" => "/workspace/my/kettle-soup-cover"
      )
    end

    it "supports alternate family prefixes" do
      env["KETTLE_DEV_DEV"] = "relative/path"

      expect(
        resolver.gems(
          gems: gems,
          prefix: "KETTLE_DEV",
          vendored_gems_env: "KETTLE_DEV_VENDORED_GEMS",
          vendor_gem_dir_env: "KETTLE_DEV_VENDOR_GEM_DIR"
        )
      ).to include("kettle-dev" => "/home/test/relative/path/kettle-dev")
    end

    it "ignores unknown future keyword options" do
      env["NOMONO_GEMS_DEV"] = "/workspace/my"

      expect(
        resolver.gems(gems: %w[kettle-dev], future_option: "ignored")
      ).to eq("kettle-dev" => "/workspace/my/kettle-dev")
    end

    it "normalizes configured path aliases before returning gem paths" do
      env["KETTLE_DEV_DEV"] = "/var/home/test/src/my"
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with("/var/home/test").and_return("/mnt/home/test")
      allow(File).to receive(:realpath).with("/home/test").and_return("/mnt/home/test")

      expect(
        resolver.gems(
          gems: %w[kettle-dev],
          prefix: "KETTLE_DEV",
          path_aliases: {"/var/home/test" => "/home/test"}
        )
      ).to eq("kettle-dev" => "/home/test/src/my/kettle-dev")
    end

    it "normalizes vendored gem paths with configured path aliases" do
      env["KETTLE_DEV_DEV"] = "/var/home/test/src/my"
      env["VENDORED_GEMS"] = "kettle-test"
      env["VENDOR_GEM_DIR"] = "/var/home/test/src/my/vendor"
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with("/var/home/test").and_return("/mnt/home/test")
      allow(File).to receive(:realpath).with("/home/test").and_return("/mnt/home/test")

      expect(
        resolver.gems(
          gems: gems,
          prefix: "KETTLE_DEV",
          path_aliases: [["/var/home/test", "/home/test"]]
        )
      ).to include("kettle-test" => "/home/test/src/my/vendor/kettle-test")
    end

    it "supports path aliases from family env configuration" do
      env["KETTLE_DEV_DEV"] = "/var/home/test/src/my"
      env["KETTLE_DEV_PATH_ALIASES"] = "/var/home/test=/home/test"
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with("/var/home/test").and_return("/mnt/home/test")
      allow(File).to receive(:realpath).with("/home/test").and_return("/mnt/home/test")

      expect(
        resolver.gems(gems: %w[kettle-dev], prefix: "KETTLE_DEV")
      ).to eq("kettle-dev" => "/home/test/src/my/kettle-dev")
    end

    it "supports global path aliases env fallback" do
      env["KETTLE_DEV_DEV"] = "/var/home/test/src/my"
      env["NOMONO_PATH_ALIASES"] = "/var/home/test=/home/test"
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with("/var/home/test").and_return("/mnt/home/test")
      allow(File).to receive(:realpath).with("/home/test").and_return("/mnt/home/test")

      expect(
        resolver.gems(gems: %w[kettle-dev], prefix: "KETTLE_DEV")
      ).to eq("kettle-dev" => "/home/test/src/my/kettle-dev")
    end

    it "uses the most specific matching path alias" do
      env["KETTLE_DEV_DEV"] = "/var/home/test/src/my"
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with("/var/home/test").and_return("/mnt/home/test")
      allow(File).to receive(:realpath).with("/home/test").and_return("/mnt/home/test")
      allow(File).to receive(:realpath).with("/var/home/test/src").and_return("/mnt/home/test/src")
      allow(File).to receive(:realpath).with("/workspace/src").and_return("/mnt/home/test/src")

      expect(
        resolver.gems(
          gems: %w[kettle-dev],
          prefix: "KETTLE_DEV",
          path_aliases: {
            "/var/home/test" => "/home/test",
            "/var/home/test/src" => "/workspace/src"
          }
        )
      ).to eq("kettle-dev" => "/workspace/src/my/kettle-dev")
    end

    it "rejects path aliases that do not resolve to the same directory" do
      env["KETTLE_DEV_DEV"] = "/var/home/test/src/my"
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with("/var/home/test").and_return("/mnt/home/test")
      allow(File).to receive(:realpath).with("/home/test").and_return("/other/home/test")

      expect do
        resolver.gems(
          gems: %w[kettle-dev],
          prefix: "KETTLE_DEV",
          path_aliases: {"/var/home/test" => "/home/test"}
        )
      end.to raise_error(Nomono::Error, %r{does not resolve to the same directory})
    end

    it "rejects malformed path alias env entries" do
      env["NOMONO_GEMS_DEV"] = "/workspace/my"
      env["NOMONO_GEMS_PATH_ALIASES"] = "/var/home/test"

      expect do
        resolver.gems(gems: %w[kettle-dev])
      end.to raise_error(Nomono::Error, "path aliases must be configured as source=canonical pairs")
    end

    it "wraps realpath system errors when path aliases cannot be verified" do
      env["NOMONO_GEMS_DEV"] = "/workspace/my"
      allow(File).to receive(:realpath).with("/var/home/test").and_raise(Errno::ENOTDIR, "/var/home/test")

      expect do
        resolver.gems(
          gems: %w[kettle-dev],
          path_aliases: {"/var/home/test" => "/home/test"}
        )
      end.to raise_error(Nomono::Error, %r{cannot be verified})
    end

    it "prints resolved paths when debug mode is enabled" do
      env["NOMONO_GEMS_DEV"] = "/workspace/my"
      env["KETTLE_DEV_DEBUG"] = "yes"

      expect do
        resolver.gems(gems: %w[kettle-dev])
      end.to output(%r{Nomono gem_paths: \{"kettle-dev"\s*=>\s*"/workspace/my/kettle-dev"\}}).to_stdout
    end

    it "rejects invalid gem names" do
      env["NOMONO_GEMS_DEV"] = "true"

      expect do
        resolver.gems(gems: ["../kettle-dev"])
      end.to raise_error(Nomono::Error, /gem names must match/)
    end

    it "rejects non-allowlisted gem names in strict mode" do
      env["NOMONO_GEMS_DEV"] = "true"

      expect do
        resolver.gems(gems: %w[kettle-dev], allowlist: %w[kettle-test])
      end.to raise_error(Nomono::Error, "gem 'kettle-dev' is not allowlisted")
    end

    it "allows non-allowlisted gem names outside strict mode" do
      env["NOMONO_GEMS_DEV"] = "true"

      expect(
        resolver.gems(gems: %w[kettle-dev], allowlist: %w[kettle-test], strict: false)
      ).to eq("kettle-dev" => "/home/test/src/my/kettle-dev")
    end
  end
end
