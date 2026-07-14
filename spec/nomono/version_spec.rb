# frozen_string_literal: true

require "spec_helper"
require "nomono/version_gem"

RSpec.describe Nomono::Version do
  it_behaves_like "a Version module", described_class
end
