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
      env["KETTLE_RB_DEV"] = "relative/path"

      expect(
        resolver.gems(
          gems: gems,
          prefix: "KETTLE_RB",
          vendored_gems_env: "KETTLE_RB_VENDORED_GEMS",
          vendor_gem_dir_env: "KETTLE_RB_VENDOR_GEM_DIR"
        )
      ).to include("kettle-dev" => "/home/test/relative/path/kettle-dev")
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
