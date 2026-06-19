# vista-rpc

Pure-Ruby RPC client for VistA's XWB / CIA broker protocol. Covers stock VistA
and kernel RPC namespaces:

- `ORWPT`, `ORWU`, `ORWPCE`, `ORWLRR`, `ORWRA`, `ORWRP`, `ORWOR`, `ORWORR`,
  `ORWDAL32`, `ORQQ*`
- `XUS`, `XU`, `XQAL`, `XM`
- `TIU`, `GMTS`, `GMV`, `MAG`, `PXRM`, `PSO`, `ORWDXC`
- `CIAVMRPC`, `CIAVMCFG`, `CIAVCXUS` (CIA Broker session bootstrap)

For IHS-specific RPC namespaces (`BHD`, `BIPC`, `BMC`, `BEHO`, `BPHR`, `BQI`,
`BGO`, `MAGG`, etc.) use the companion gem
[`rpms-rpc`](https://github.com/lakeraven/rpms-rpc), which depends on this one.

## Status

Initial bootstrap. The full code extraction from `rpms-rpc` lands in follow-on
PRs — see [`docs/CLASSIFICATION.md`](docs/CLASSIFICATION.md) for the partition
plan.

## Install

```ruby
# Gemfile
gem "vista-rpc"
```

```sh
bundle install
```

## Usage

```ruby
require "vista_rpc"

VistaRpc.configure do |c|
  c.client = VistaRpc::CiaClient.new(host: "vista.example.org", port: 8994)
end

# ... after code extraction lands
# VistaRpc::Patient.find(dfn)
```

## License

MIT. See [`MIT-LICENSE`](MIT-LICENSE).
