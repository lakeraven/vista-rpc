# frozen_string_literal: true

require_relative "lib/vista_rpc/version"

Gem::Specification.new do |spec|
  spec.name        = "vista-rpc"
  spec.version     = VistaRpc::VERSION
  spec.authors     = [ "Lakeraven" ]
  spec.email       = [ "eng@lakeraven.com" ]
  spec.homepage    = "https://github.com/lakeraven/vista-rpc"
  spec.summary     = "Pure Ruby RPC client for VistA (XWB / CIA broker protocol)"
  spec.description = "Pure Ruby gem providing wire-level access to VistA RPC brokers " \
                     "via the XWB / CIA protocol. Covers stock VistA and kernel RPC " \
                     "namespaces (ORWPT, ORWU, ORWPCE, ORQQ*, TIU, XUS, etc.). The " \
                     "IHS-specific layer (BHD, BIPC, BMC, BEHO, BPHR, BQI, BGO, MAGG) " \
                     "lives in the companion lakeraven/rpms-rpc gem, which depends on " \
                     "this one. No Rails dependency."
  spec.license     = "MIT"
  spec.metadata    = {
    "homepage_uri"      => "https://github.com/lakeraven/vista-rpc",
    "source_code_uri"   => "https://github.com/lakeraven/vista-rpc",
    "changelog_uri"     => "https://github.com/lakeraven/vista-rpc/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/lakeraven/vista-rpc/tree/main/docs"
  }

  spec.required_ruby_version = ">= 3.4.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib,docs}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rexml", "~> 3.2"
end
