# frozen_string_literal: true

RSpec.describe Nomono::GemfileDsl do
  let(:dsl_class) do
    Class.new do
      include Nomono::GemfileDsl

      attr_reader :captured

      def gem(name, **options)
        @captured ||= []
        @captured << [name, options]
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
end
