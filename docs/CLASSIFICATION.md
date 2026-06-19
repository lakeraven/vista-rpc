# vista-rpc / rpms-rpc partition

The split: stock VistA + kernel namespaces live in `vista-rpc`; the
IHS-specific layer lives in `rpms-rpc` (which gem-depends on `vista-rpc`).

This document records the planned move for each module in
`lakeraven/rpms-rpc/lib/rpms_rpc/api/` so the extraction can land in
small, reviewable PRs without ambiguity.

## Stock VistA — moves to `vista-rpc/lib/vista_rpc/api/`

These modules use only stock VistA / kernel RPC namespaces. They move
to `vista-rpc` with namespace rename `RpmsRpc::Xxx` → `VistaRpc::Xxx`.

| Module | Primary RPC namespaces |
|---|---|
| `allergy` | `ORQQAL` |
| `authentication` | `XUS`, `ORWU` |
| `care_plan` | `ORQQCP` |
| `care_team` | `ORQQCT` |
| `communication` | `XM`, `XQAL` |
| `device` | `ORWPCE` (IMPLANT) |
| `e_signature` | `TIU`, `ORWU` |
| `eprescribing` | `PSO` |
| `goal` | `ORQQGO` |
| `lab` | `ORWLRR` |
| `medication` | `ORQQPS` |
| `note_template` | `TIU` |
| `order` | `ORWOR`, `ORWORR` |
| `practitioner` | `ORWU` |
| `progress_note` | `TIU` |
| `radiology` | `ORWRA` |
| `symptom` | `ORWDAL32` |
| `user_management` | `ORWU`, `XUS`, `XU` |

## IHS-only — stays in `rpms-rpc`

These modules use only IHS-namespaced RPCs and remain in `rpms-rpc`
after extraction.

| Module | Primary RPC namespaces |
|---|---|
| `chs_budget` | `BMCRPC` |
| `eligibility` | `BIPC` |
| `exam_component` | `BGOVUPD` |
| `health_factor` | `BGOVUPD` |
| `immunization` | `BIPC`, `BEHOCIR` |
| `immunization_exchange` | `BYIMRT` |
| `immunization_refusal` | `BGOREP` |
| `location` | `BHDO` |
| `measurement` | `BGOVUPD` |
| `notifications` | `BQI` |
| `organization` | `BHDO` |
| `pov` | `BGOVUPD` |
| `rcis_site_params` | `BMCRPC` |
| `reminders` | `BGOTRG` |
| `session` | `CIAVMRPC`, `CIAVMCFG`, `CIAVCXUS` |
| `site` | `BEHOSICX` |
| `tribal` | `BHDPTRPC` |
| `vaccine_lot` | `BIPC` |
| `vendor` | `BMCRPC` |

## Mixed — split, then move the stock half

These modules touch both stock VistA and IHS namespaces. Recommended
split for each (stock half moves to `vista-rpc`, IHS half stays in
`rpms-rpc` and depends on the moved stock half).

| Module | Stock part (moves) | IHS part (stays) |
|---|---|---|
| `encounter` | `for_patient` (`ORWPT`) | `open` (`BEHOENCX`) |
| `health_summary` | `for_patient`, `generate_selective`, `component_data` (`ORWRP`, `ORQQPX`) | `personal_wellness_report`, `flowsheet`, `health_maintenance` (`GMTS`) |
| `image` | `exams_for_patient` (`ORWRA`) | `launch_token` (`MAGG`) |
| `patient` | `find`, `search` (`ORWPT`) | `brief_header` (`BEHOPTCX`, `BEHOPTPC`, `BEHOCACV`) |
| `phr` | — | All paths (`BEHOCCD`, `BEHOCIR`, `BPHR`) — stays |
| `problem` | `for_patient` (`ORQQPL`) | `add`, `update`, `delete`, `filter` (`BGOPROB*`) |
| `procedure` | `for_patient` (`ORWPCE`) | `add` (`BGOVCPT`) |
| `referral` | `for_patient`, `find` (`BMC`) | `create`, `delete` (`BGOREF`) |
| `vital` | — | All paths (`BEHOVM`) — stays |

Note: `BMC` is IHS-specific despite the classifier flagging it as stock —
the referral surface only exists on RPMS installs. `referral` may end
up fully on the IHS side once verified.

## Shared infrastructure — moves to `vista-rpc`

Both gems need the broker client, mapping framework, and response
parsing. These move to `vista-rpc` and become the dependency surface
that `rpms-rpc` consumes.

- `cia_client.rb`, `client.rb`, `mock_client.rb`
- `data_mapper.rb`, `mappings.rb` (the mappings registry framework;
  the IHS-namespaced `DataMapper.define` entries themselves stay in
  `rpms-rpc` and register against the shared registry at load time)
- `parameter_encoder.rb`
- `response_parser.rb`, `xml_response_parser.rb`
- `fileman_date_parser.rb`
- `phi_sanitizer.rb`
- `server_capabilities.rb` (framework; IHS-feature entries stay in `rpms-rpc`)
- `security_keys.rb`, `user_roles.rb`, `capabilities.rb`

`bmx_client.rb` (BMX SQL bridge) is a separate concern — that work
lives in `lakeraven/rpms-sql`. It will be removed from `rpms-rpc` in
the same wave.

## PR sequence

1. **vista-rpc bootstrap** (this PR) — gemspec, version, license, README, this
   classification doc, sample test.
2. **Move shared infrastructure to `vista-rpc`** — broker client, mappings
   framework, parameter encoder, response parsers, FileMan date parser,
   PHI sanitizer.
3. **Move stock VistA API modules to `vista-rpc`** — the 18 STOCK_VISTA
   files listed above plus their mappings.rb entries.
4. **Refactor `rpms-rpc` to depend on `vista-rpc`** — declare the gem
   dependency, remove the moved files, add `RpmsRpc` → `VistaRpc`
   re-export shims for any engine call sites that haven't been
   migrated yet.
5. **Split MIXED modules** — extract the stock half from each of the 8
   mixed files (patient, encounter, health_summary, problem,
   procedure, referral, image, plus reconsider phr/vital).
6. **Migrate `lakeraven-ehr` engine** to use `VistaRpc::*` where it now
   makes sense; drop the shims.

Each step is a separate PR. Step 1 ships a usable (empty) gem; steps 2–4
ship a usable gem with real APIs while keeping `rpms-rpc` consumers
green; steps 5–6 are cleanup that can land asynchronously.
