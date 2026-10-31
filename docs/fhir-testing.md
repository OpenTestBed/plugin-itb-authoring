# What this does for FHIR testing

Three things ship together and only make sense together: a **test language**, a
**FHIR validator service with a vocabulary of its own**, and a **dialect
architecture** that lets a FHIR test reach outside FHIR. This page is what to
say when someone asks what the set is for.

The one-sentence version: **you write conformance tests as readable scenarios,
and you get back both something a test bed can execute and something the FHIR
ecosystem can publish — an implementation guide carrying a `TestPlan` per
actor.**

---

## 1. The language: executable conformance statements

`@opentestbed/otb-gherkin` (core language `itb-core-en`, spec version 2.1.0, 78
core verbs) is Gherkin with a fixed grammar. **Six sentence shapes, and dialects
may add verbs but never shapes.** That constraint is the whole reason the
language stays readable as the vocabulary grows.

```gherkin
Given Server is the system under test
  And FHIRValidator is a fhir-validator at "http://localhost:8088"
 When Client gets from Server at "/Patient/example" as $patient
 Then $response.status should be 200
  And $patient should conform to "http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips"
```

What that buys you, specifically for FHIR:

**Profile conformance is a sentence, not a scriptlet.** `should conform to
<canonical>` is a first-class shape, with `ignoring slicing errors` and
`ignoring errors matching "<pattern>"` for the cases every IG author knows
about. The thing you most often want to assert about a FHIR instance is the
thing the language says most directly.

**FHIRPath is in the assertion layer.** Every comparator has an `at <path>`
form — `$bundle at "entry.resource.ofType(Patient).count()" should be 1` — so
you are not reduced to string matching on a response body. Around 30
comparators, each in a plain and an `at <path>` variant.

**One system under test per scenario, declared.** `is the system under test`
versus `is infrastructure` is not decoration: it is what makes a suite
*actor-scoped* in the way IHE profiles and FHIR IGs with `ActorDefinition`
already are. A scenario states which role is being judged, and everything else
is scaffolding.

**You can test clients, not only servers.** This is the part most FHIR test
tooling does not do. The test bed can *be* the peer:

```gherkin
Given Server is listening for Client
 When Server receives a request from Client within 30 seconds
 Then $received.method should be "POST"
  And Server replies to Client with status 201 and body $created
```

So a suite can cover an IHE Document Source, an IUA Authorization Client, a
SMART app — any actor whose obligation is to *send* something correctly. An IG
that defines two actors gets tests for both, not just the one that happens to
expose an endpoint.

**Requirements no request can settle have a home.** `is informed`, `is asked
for`, `uploads a file as`, `submits evidence of`, and `confirms each of these is
<word>` put operator attestation inside the same suite as the automated steps,
with the same verdict machinery. FHIR IGs are full of SHALLs about what a system
*displays* or how an organisation *governs* something. Those stop being a
separate spreadsheet.

---

## 2. The FHIR validator dialect: the FHIR-specific verbs

21 verbs on top of a validator service. The interesting ones are not
"validate this".

| Capability | What it lets a test do |
|---|---|
| **Package and IG loading** | `FHIRValidator is loaded with package "hl7.fhir.uv.ips#2.0.0"`, `loads IG` — the suite declares the version of the spec it judges against |
| **Profile validation** | `validates <ref> against <canonical>` plus a table form for options |
| **FHIRPath evaluation** | `evaluates "<expr>" on <ref> as $x` — bind a computed value and carry it onward, not just assert on it |
| **Matchetype comparison** | `should match pattern:` / `should not match pattern:` — compare a response against an expected shape with tolerance for ids, timestamps, uuids and the other things that legitimately differ per run |
| **Test data generation** | `generates required test data from <canonical> as $x`, with a values table or a mappings resource — **instances derived from the IG's own profiles**, so the fixtures cannot drift from the spec |
| **Deliberate corruption** | `modifies <ref> against <canonical> with operations:` — take a valid instance and break it in one named way. This is how you get negative tests that are honestly derived rather than hand-written and stale |
| **StructureMap / FML** | `transforms <ref> with map <canonical>`, `parses FML`, `registers StructureMap` — mapping logic becomes testable |

The generation-plus-corruption pair is the one worth dwelling on. A suite's
weakest point is usually its negative cases: someone wrote an invalid Patient by
hand in 2023 and nobody can now say which rule it was meant to violate. Here the
valid instance comes from the profile and the invalidity is a named operation, so
the test says what it is testing.

---

## 3. The dialect architecture: FHIR testing is never only FHIR

This is the structural claim, and the reason the set is a set.

Open a real FHIR conformance problem and it stops being FHIR almost immediately.
IHE IUA is OAuth 2.1 token endpoints, JWT claim structure, *and* FHIR resource
access. SMART on FHIR is the same. A verifiable health link is QR encoding and
HCERT decoding before any Bundle is validated. Terminology conformance is
`$expand` and `$validate-code` request/response pairs. Put all of that in one
language and you get a language nobody can read.

A **dialect** is a vocabulary — verbs, actor kinds, value types — and
*optionally* a service behind it. It declares itself in `component.yml`:

```yaml
id: fhir-terminology
actors:
  - id: TxServer
language:
  steps: steps.yml
  version: "1.0.0"
  base: itb-core-en
  baseVersion: ">=2 <3"      # which core language versions this fits
```

Four properties follow from that, each solving a problem you otherwise hit
later:

**Dialects are versioned against the core.** `baseVersion` is a semver range. A
core language change that breaks a dialect produces a diagnostic naming both
versions, instead of a mysterious "no mapping for step".

**A dialect need not ship a service.** `provides: []` in the registry is a
deliberate statement, not an omission. `oauth`, `jwt` and `fhir-terminology` are
vocabulary and nothing else — because in those cases the thing being tested *is*
the counterparty. A terminology server does not need a simulated terminology
server.

**Dialects borrow capabilities instead of duplicating them.** `requires:` in the
registry: `jwt` borrows the validator's FHIRPath endpoint to decode a token,
`fhir-terminology` borrows its matchetype service to compare a `Parameters`
response. One comparison engine, several dialects.

**A feature file enables several dialects at once — so you can test the
intersection of specifications.** This is the capability that is hard to get any
other way. Real deployments are not "one IG at a time": they are an IPS document
*fetched through* an MHD transaction *authorised by* an IUA token. A scenario
that declares the FHIR validator, the OAuth and the JWT dialects together tests
the overlap where those specs meet — the place where conformance to each one
separately proves the least.

The registry (`OpenTestBed/itb-plugins`, `index.yaml`) is also allowed to be
honest: `status: spec-only` with a `reason` marks a dialect that compiles but has
no service to run against, so the picture is complete rather than quietly
pruned.

---

## 4. The output: a FHIR Test Package

Feature files are the source. The deliverable the FHIR world can consume is an
**implementation guide** that carries:

- one **`TestPlan`** per actor, with `TestPlan.suite.input.file` naming the
  script, each `test` corresponding to a Scenario, each `assertion.human` to a
  step;
- the **Gherkin itself as `Binary` resources**, rendered as pages — the test is
  readable in the published IG, not hidden in a repository;
- a **`dist/package.tgz`**, installable with ordinary FHIR package tooling.

The compiled GITB TDL test suite goes to an Interoperability Test Bed and
executes; the IG is how the tests are *published, cited and reviewed*. An IG
author can point at a `TestPlan` in a ballot comment.

One integrity property is enforced rather than hoped for: `check-test-ig.mjs`
fails the build if any plan names no script, names a script with no `Scenario:`,
or carries an assertion that appears nowhere in the feature file. The last of
those is the dangerous one — an **assertion on the side** makes a plan look
*more* thorough than the suite actually is, and it is the one defect nobody
catches by reading.

---

## 5. What this is not, and what is still missing

This section is as much the answer as the rest of it.

**Not a replacement for the FHIR validator, or for `TestScript`.** The validator
does the validating; this layer decides what to validate, in what order, against
which actor, and what counts as a pass. `TestPlan` here is a declaration of a
Gherkin script, not a competing execution format.

**Authoring and packaging need only Node 18+. Executing needs an
Interoperability Test Bed.** Compiling proves a suite is well-formed. It proves
nothing about the system under test — and a suite that has only ever compiled
should be described that way.

Known gaps, as of 2026-10-30:

- The matchetype capability does not yet perform three normalisations that the
  upstream HL7 terminology tests rely on;
  `itb-plugins/capabilities/fhir-matchetype.yaml` states which. The
  `fhir-terminology` dialect can delegate a whole upstream test to the HL7
  runner instead, which uses `CompareUtilities` directly.
- The `archimate` dialect is `spec-only`: the vocabulary is complete, the
  service it is written against has not been built.
- Six core-language gaps are documented but unimplemented — `{value}` not being
  able to carry an expression is the one most often felt. See
  `packages/gherkin/RFC-core-gaps.md` in `OpenTestBed/itb-cli`.
- The IUA and EU Health Data Access suites are authored and compile; neither has
  been executed against a live system yet.

---

## Where to start

| You want to | Read |
|---|---|
| Build your first test package, step by step | [first-test-package.md](first-test-package.md) |
| See the whole story as a presentation | [walkthrough.md](walkthrough.md) |
| Reference: install, compile, package | [../README.md](../README.md) |
| Add verbs for a service that has none | the `add-language-dialect` skill |
| Change the core language itself | the `change-core-language` skill |
