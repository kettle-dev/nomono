# frozen_string_literal: true

require "bundler"
require "tmpdir"
require "fileutils"

RSpec.describe Nomono::GemfileDsl, "#eval_nomono_gems" do
  around do |example|
    Dir.mktmpdir("nomono-bundler-", ENV.fetch("TMPDIR", nil)) do |root|
      @root = root
      @sibling = File.join(root, "sibling")
      FileUtils.mkdir_p(@sibling)
      File.write(File.join(@sibling, "sibling.gemspec"), <<~RUBY)
        Gem::Specification.new do |spec|
          spec.name = "sibling"
          spec.version = "7.1.14"
          spec.summary = "Local sibling fixture"
          spec.authors = ["Nomono specs"]
        end
      RUBY
      File.write(File.join(root, "owner.gemspec"), <<~RUBY)
        Gem::Specification.new do |spec|
          spec.name = "owner"
          spec.version = "7.1.14"
          spec.summary = "Owner fixture"
          spec.authors = ["Nomono specs"]
          spec.add_runtime_dependency "sibling", "= 7.1.14"
        end
      RUBY
      example.run
    end
  end

  before do
    allow(Nomono).to receive(:resolver).and_return(
      Nomono::Resolver.new(env: {"FAMILY_DEV" => @root})
    )
  end

  def evaluate(body)
    path = File.join(@root, "Gemfile")
    File.write(path, body)
    Bundler::Dsl.new.extend(described_class).tap { |dsl| dsl.eval_gemfile(path) }
  end

  it "accepts a runtime gemspec exact requirement plus a matching path gem without repeating the requirement" do
    dsl = evaluate(<<~RUBY)
      gemspec
      eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"
    RUBY

    dependency = dsl.dependencies.find { |item| item.name == "sibling" }
    expect(dependency.requirement.to_s).to eq(">= 0")
    expect(dependency.source).to be_a(Bundler::Source::Path)
    expect(dependency.source.specs.find { |spec| spec.name == "sibling" }.version.to_s).to eq("7.1.14")
  end

  it "declares the supplied fact requirement on a local path source" do
    dsl = evaluate(<<~RUBY)
      gemspec
      eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => ["= 7.1.14"]}, path_env: "FAMILY_DEV"
    RUBY

    dependency = dsl.dependencies.find { |item| item.name == "sibling" }
    expect(dependency.requirement.to_s).to eq("= 7.1.14")
    expect(dependency.source).to be_a(Bundler::Source::Path)
  end

  it "does not disguise duplicate direct declarations with unequal requirements as a resolver failure" do
    expect do
      evaluate(<<~RUBY)
        gem "sibling", "= 7.1.14"
        eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"
      RUBY
    end.to raise_error(Bundler::Dsl::DSLError, /different version requirements/)
  end

  it "does not disguise duplicate direct sources by merely repeating their version requirement" do
    expect do
      evaluate(<<~RUBY)
        gem "sibling", "= 7.1.14"
        eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => ["= 7.1.14"]}, path_env: "FAMILY_DEV"
      RUBY
    end.to raise_error(Bundler::Dsl::DSLError, /different sources/)
  end
end
