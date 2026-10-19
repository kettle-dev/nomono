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
      write_owner(:runtime, "= 7.1.14")
      # These fixtures have no lockfile and must exercise resolution regardless
      # of the parent bundle's deployment/frozen and group-selection settings.
      Bundler.settings.temporary(frozen: false, deployment: false, without: [], with: []) do
        example.run
      end
    end
  end

  before do
    allow(Nomono).to receive(:resolver).and_return(
      Nomono::Resolver.new(env: {"FAMILY_DEV" => @root})
    )
  end

  def write_owner(type, requirement)
    File.write(File.join(@root, "owner.gemspec"), <<~RUBY)
      Gem::Specification.new do |spec|
        spec.name = "owner"
        spec.version = "7.1.14"
        spec.summary = "Owner fixture"
        spec.authors = ["Nomono specs"]
        spec.add_#{type}_dependency "sibling", #{requirement.inspect}
      end
    RUBY
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
        gem "sibling", path: #{@sibling.inspect}
      RUBY
    end.to raise_error(Bundler::Dsl::DSLError, /different version requirements/)
  end

  it "does not disguise duplicate direct sources by merely repeating their version requirement" do
    expect do
      evaluate(<<~RUBY)
        gem "sibling", "= 7.1.14"
        gem "sibling", "= 7.1.14", path: #{@sibling.inspect}
      RUBY
    end.to raise_error(Bundler::Dsl::DSLError, /different sources/)
  end

  it "honors a direct declaration made after the local override" do
    dsl = evaluate(<<~RUBY)
      eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1.14"]}, path_env: "FAMILY_DEV"
      gem "sibling", "~> 7.1", group: :test, require: "sibling/custom"
    RUBY

    expect(dsl.dependencies.size).to eq(1)
    dependency = dsl.dependencies.first
    expect(dependency.requirement.as_list).to contain_exactly("~> 7.1", ">= 7.1.14")
    expect(dependency.groups).to eq([:test])
    expect(dependency.autorequire).to eq(["sibling/custom"])
    expect(dependency.source).to be_a(Bundler::Source::Path)
    expect(dsl.to_definition(nil, true).resolve.map(&:name)).to include("sibling")
  end

  %i[runtime development].each do |type|
    %i[before after].each do |order|
      context "with a #{type} gemspec dependency declared #{order} the macro" do
        def owner_body(order, explicit = "")
          local = 'eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1"]}, path_env: "FAMILY_DEV"'
          [explicit, *((order == :before) ? ["gemspec", local] : [local, "gemspec"])].join("\n")
        end

        it "resolves the registered local source while retaining the gemspec constraint" do
          write_owner(type, "= 7.1.14")
          dsl = evaluate(owner_body(order))
          expect(dsl.dependencies.count { |dep| dep.name == "sibling" }).to eq(1)
          expect(dsl.to_definition(nil, true).resolve.map(&:name)).to include("owner", "sibling")
          if type == :development
            dependency = dsl.dependencies.find { |dep| dep.name == "sibling" }
            expect(dependency.requirement.as_list).to include("= 7.1.14", ">= 7.1")
            expect(dependency.groups).to eq([:development])
          end
        end

        it "rejects a local version outside the gemspec constraint during resolution" do
          write_owner(type, "= 7.1.15")
          dsl = evaluate(owner_body(order))
          expect { dsl.to_definition(nil, true).resolve }.to raise_error(Bundler::BundlerError, /sibling/)
        end

        it "keeps both the explicit direct and gemspec constraints" do
          write_owner(type, ">= 7.1.15")
          dsl = evaluate(owner_body(order, 'gem "sibling", "~> 7.1", group: :test, require: false'))
          dependency = dsl.dependencies.find { |dep| dep.name == "sibling" }
          expect(dependency.requirement.as_list).to include("~> 7.1", ">= 7.1")
          expect(dependency.groups).to eq([:test])
          expect(dependency.autorequire).to be_empty
          expect { dsl.to_definition(nil, true).resolve }.to raise_error(Bundler::BundlerError, /sibling/)
        end
      end
    end
  end

  %i[before after].each do |order|
    it "rejects an incompatible direct requirement declared #{order} the macro" do
      direct = 'gem "sibling", "= 7.1.15"'
      local = 'eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1"]}, path_env: "FAMILY_DEV"'
      dsl = evaluate(((order == :before) ? [direct, local] : [local, direct]).join("\n"))
      expect(dsl.dependencies.size).to eq(1)
      expect(dsl.dependencies.first.requirement.as_list).to include("= 7.1.15", ">= 7.1")
      expect { dsl.to_definition(nil, true).resolve }.to raise_error(Bundler::GemNotFound, /sibling/)
    end
  end

  it "does not relax a direct constraint when no requirements map entry is supplied" do
    dsl = evaluate(<<~RUBY)
      gem "sibling", "= 7.1.15", group: :development
      eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"
    RUBY
    expect(dsl.dependencies.first.requirement.as_list).to eq(["= 7.1.15"])
    expect { dsl.to_definition(nil, true).resolve }.to raise_error(Bundler::GemNotFound, /sibling/)
  end

  it "intersects contradictory facts rather than replacing a direct requirement" do
    dsl = evaluate(<<~RUBY)
      gem "sibling", "= 7.1.14"
      eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1.15"]}, path_env: "FAMILY_DEV"
    RUBY
    expect(dsl.dependencies.first.requirement.as_list).to contain_exactly("= 7.1.14", ">= 7.1.15")
    expect { dsl.to_definition(nil, true).resolve }.to raise_error(Bundler::GemNotFound, /sibling/)
  end

  it "makes repeated macro calls idempotent without losing later declaration metadata" do
    dsl = evaluate(<<~RUBY)
      2.times { eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1"]}, path_env: "FAMILY_DEV" }
      gem "sibling", "~> 7.1", group: :development, require: false
      2.times { eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1"]}, path_env: "FAMILY_DEV" }
    RUBY
    expect(dsl.dependencies.size).to eq(1)
    dependency = dsl.dependencies.first
    expect(dependency.requirement.as_list).to contain_exactly("~> 7.1", ">= 7.1")
    expect(dependency.groups).to eq([:development])
    expect(dependency.autorequire).to be_empty
    expect(dsl.to_definition(nil, true).resolve.map(&:name)).to include("sibling")
  end

  [true, false].each do |enabled|
    %i[before after].each do |order|
      it "retains evaluated install_if=#{enabled}, env, platform, group and loading metadata with the declaration #{order}" do
        direct = <<~RUBY
          group :development, :test, optional: true do
            platforms :ruby, :jruby do
              env "NOMONO_SPEC_CONDITION" => "enabled" do
                install_if -> { #{enabled} } do
                  gem "sibling", "~> 7.1", require: false, force_ruby_platform: true
                end
              end
            end
          end
        RUBY
        local = 'eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1"]}, path_env: "FAMILY_DEV"'
        dsl = evaluate(((order == :before) ? [direct, local] : [local, direct]).join("\n"))
        dependency = dsl.dependencies.first
        expect(dependency.groups).to eq([:development, :test])
        expect(dependency.platforms).to eq([:ruby, :jruby])
        expect(dependency.autorequire).to be_empty
        expect(dependency.force_ruby_platform).to be(true)
        # Bundler 2 keeps env/install_if state in ivars, without Bundler 4's
        # readers. Assert behavior through their shared public predicates.
        # Platform selection is orthogonal and differs on TruffleRuby.
        allow(dependency).to receive(:current_platform?).and_return(true)
        stub_env("NOMONO_SPEC_CONDITION" => "enabled")
        expect(dependency).to be_current_env
        expect(dependency.should_include?).to be(enabled)
        stub_env("NOMONO_SPEC_CONDITION" => "disabled")
        expect(dependency).not_to be_current_env
        expect(dependency.should_include?).to be(false)
      end
    end
  end

  it "duplicates existing effective state and clears cached git source metadata only" do
    dsl = evaluate(<<~RUBY)
      gem "sibling", "~> 7.1", git: "file:///nonexistent/nomono-fixture", branch: "main", ref: "abc", glob: "old/*.gemspec", require: "custom"
      @original = dependencies.first
      @original.instance_variable_set(:@future_metadata, :retained)
      [:source, :path, :git, :github, :branch, :ref, :glob, :groups, :platforms, :autorequire, :env, :force_ruby_platform].each do |key|
        @original.public_send(key) if @original.respond_to?(key)
      end
      eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"
    RUBY
    original = dsl.instance_variable_get(:@original)
    dependency = dsl.dependencies.first
    expect(dependency).not_to equal(original)
    expect(dependency.instance_variable_get(:@future_metadata)).to eq(:retained)
    expect(dependency.autorequire).to eq(["custom"])
    expect(dependency.path).to eq(@sibling)
    expect([dependency.git, dependency.github, dependency.branch, dependency.ref, dependency.glob]).to all(be_nil)
    expect(original.source).to be_a(Bundler::Source::Git)
    expect(original.git).to eq("file:///nonexistent/nomono-fixture")
    expect(original.branch).to eq("main")
    expect(dependency.source).to be_a(Bundler::Source::Path)
    expect(dsl.to_definition(nil, true).resolve.map(&:name)).to include("sibling")
  end

  it "keeps a displaced source that an enclosing block uses for a later gem" do
    dsl = evaluate(<<~RUBY)
      git "file:///nonexistent/nomono-fixture" do
        gem "sibling", "~> 7.1"
        eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"
        @source_still_registered = @sources.git_sources.include?(@source)
        gem "other"
      end
    RUBY
    expect(dsl.instance_variable_get(:@source_still_registered)).to be(true)
    other = dsl.dependencies.find { |dep| dep.name == "other" }
    expect(other.source).to be_a(Bundler::Source::Git)
    dsl.to_definition(nil, true)
    expect(dsl.instance_variable_get(:@sources).git_sources).to include(other.source)
  end

  it "removes an unused displaced path source before resolution" do
    dsl = evaluate(<<~RUBY)
      gem "sibling", "~> 7.1", path: "nonexistent-old-checkout"
      eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"
    RUBY
    expect(dsl.to_definition(nil, true).resolve.map(&:name)).to include("sibling")
    expect(dsl.instance_variable_get(:@sources).path_sources).to eq([dsl.dependencies.first.source])
  end

  it "keeps normal duplicate declaration errors outside an intentional macro override" do
    expect do
      evaluate(<<~RUBY)
        eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"
        gem "unrelated", "= 1"
        gem "unrelated", "= 2"
      RUBY
    end.to raise_error(Bundler::Dsl::DSLError, /different version requirements/)
  end

  %i[direct gemspec local].permutation.each do |order|
    it "retains gemspec development constraints in #{order.join(" / ")} order" do
      write_owner(:development, ">= 7.1.15")
      declarations = {
        direct: 'gem "sibling", "~> 7.1", group: :test, require: false',
        gemspec: "gemspec",
        local: 'eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"'
      }
      dsl = evaluate(order.map { |key| declarations.fetch(key) }.join("\n"))
      expect(dsl.dependencies.count { |dep| dep.name == "sibling" }).to eq(1)
      dependency = dsl.dependencies.find { |dep| dep.name == "sibling" }
      expect(dependency.requirement.as_list).to contain_exactly("~> 7.1", ">= 7.1.15", *((order.first == :local) ? [">= 0"] : []))
      expect(dependency.groups).to eq([:test])
      expect(dependency.autorequire).to be_empty
      expect { dsl.to_definition(nil, true).resolve }.to raise_error(Bundler::GemNotFound, /sibling/)
    end
  end

  it "restores dependencies if Bundler rejects a later declaration" do
    dsl = evaluate('eval_nomono_gems gems: ["sibling"], path_env: "FAMILY_DEV"')
    original = dsl.dependencies.dup
    expect { dsl.gem("sibling", "invalid") }.to raise_error(Gem::Requirement::BadRequirementError)
    expect(dsl.dependencies).to eq(original)
    dsl.gem("sibling", "~> 7.1", group: :test)
    expect(dsl.dependencies.size).to eq(1)
    expect(dsl.dependencies.first.groups).to eq([:test])
    expect(dsl.dependencies.first.source).to be_a(Bundler::Source::Path)
  end

  it "overrides an existing direct dependency without relaxing its requirement or duplicating it" do
    dsl = evaluate(<<~RUBY)
      gem "sibling", "~> 7.1", group: :development, require: false
      eval_nomono_gems gems: ["sibling"], requirements: {"sibling" => [">= 7.1.14"]}, path_env: "FAMILY_DEV"
    RUBY

    expect(dsl.dependencies.size).to eq(1)
    dependency = dsl.dependencies.first
    expect(dependency.requirement.requirements).to contain_exactly(
      ["~>", Gem::Version.new("7.1")], [">=", Gem::Version.new("7.1.14")]
    )
    expect(dependency.groups).to eq([:development])
    expect(dependency.autorequire).to be_empty
    expect(dependency.source).to be_a(Bundler::Source::Path)
    expect(dsl.to_definition(nil, true).resolve.map(&:name)).to include("sibling")
  end
end
