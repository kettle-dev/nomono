# frozen_string_literal: true

require "anonymous_loader"
require "nomono/version_gem"
RSpec.describe Nomono::Version do
  it_behaves_like "a Version module", described_class

  it "executes the version file for coverage without redefining constants" do
    dir = File.expand_path("../../lib/nomono", __dir__)
    paths = %w[version.rb version_gem.rb].map { |file| File.join(dir, file) }.select { |path| File.file?(path) }
    anonymous_namespace = AnonymousLoader.load(files: paths)

    expect(anonymous_namespace::Nomono::Version::VERSION).to eq(described_class::VERSION)
  end
end
