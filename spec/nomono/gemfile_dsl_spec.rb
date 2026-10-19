# frozen_string_literal: true

RSpec.describe Nomono::GemfileDsl do
  let(:dsl_class) do
    Class.new do
      include Nomono::GemfileDsl

      attr_reader :captured

      def gem(name, *requirements, **options)
        @captured ||= []
        @captured << [name, *requirements, options]
      end
    end
  end

  let(:dsl) { dsl_class.new }

  it "evaluates gems into Gemfile gem(path:) calls" do
    env = {
      "KETTLE_DEV_DEV" => "/workspace/my"
    }
    allow(Nomono).to receive(:resolver).and_return(Nomono::Resolver.new(env: env, home: "/home/test"))

    dsl.eval_nomono_gems(gems: %w[kettle-dev], prefix: "KETTLE_DEV")

    expect(dsl.captured).to eq([
      ["kettle-dev", {path: "/workspace/my/kettle-dev"}]
    ])
  end

  it "passes fact-derived requirements through the same local-path macro" do
    env = {"FAMILY_DEV" => "/workspace/family"}
    allow(Nomono).to receive(:resolver).and_return(Nomono::Resolver.new(env: env))

    dsl.eval_nomono_gems(
      gems: %w[exact ranged unconstrained],
      requirements: {"exact" => ["= 7.1.14"], "ranged" => ["~> 24.2", ">= 24.2.6"]},
      path_env: "FAMILY_DEV"
    )

    expect(dsl.captured).to eq([
      ["exact", "= 7.1.14", {path: "/workspace/family/exact"}],
      ["ranged", "~> 24.2", ">= 24.2.6", {path: "/workspace/family/ranged"}],
      ["unconstrained", {path: "/workspace/family/unconstrained"}]
    ])
  end

  it "does not add paths when the owning family's toggle is disabled" do
    env = {"FAMILY_DEV" => "false", "CI" => "true"}
    allow(Nomono).to receive(:resolver).and_return(Nomono::Resolver.new(env: env))

    dsl.eval_nomono_gems(gems: %w[exact], requirements: {"exact" => ["= 7.1.14"]}, path_env: "FAMILY_DEV")

    expect(dsl.captured).to be_nil
  end

  it "evaluates normalized aliases into Gemfile gem(path:) calls" do
    env = {
      "KETTLE_DEV_DEV" => "/var/home/test/src/my",
      "KETTLE_DEV_PATH_ALIASES" => "/var/home/test=/home/test"
    }
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with("/var/home/test").and_return("/mnt/home/test")
    allow(File).to receive(:realpath).with("/home/test").and_return("/mnt/home/test")
    allow(Nomono).to receive(:resolver).and_return(Nomono::Resolver.new(env: env, home: "/home/test"))

    dsl.eval_nomono_gems(gems: %w[kettle-dev], prefix: "KETTLE_DEV")

    expect(dsl.captured).to eq([
      ["kettle-dev", {path: "/home/test/src/my/kettle-dev"}]
    ])
  end
end
