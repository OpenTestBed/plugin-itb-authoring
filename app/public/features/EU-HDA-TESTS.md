# EU Health Data API conformance tests — the record

**Status: authored and compiling. Not yet run.** Stages 1–3 of `spec-to-tests`
are done and stage 4 gate 1 is met. Gate 2 is **not** met: there is no
implementation configured to measure. Read section 5 before quoting any of this
as evidence.

## 1. Scope

**Specification.** EU Health Data API, `hl7.fhir.eu.health-data-api` 1.0.0-ballot,
FHIR 4.0.1. <https://hl7.eu/fhir/health-data-api/>

Read from the published package, not the website. It depends on
`ihe.iti.mhd`, `ihe.iti.pdqm`, `hl7.fhir.uv.ipa` and `hl7.fhir.eu.base`.

**Shape: actor-scoped**, and unusually well suited to it. The package carries
seven `CapabilityStatement` resources of `kind: requirements`, in client/server
pairs. Each declares, per resource type, which interactions and which search
parameters an actor must support, and each obligation carries a
`capabilitystatement-expectation` of **SHALL** or **SHOULD**. The case list
below is therefore *derived*, not invented: every case names an obligation.

| Actor | Role | Covered here |
|---|---|---|
| EEHRxF Resource Access Provider | server, 12 resource types | **yes** |
| EEHRxF Resource Consumer | client, same 12 types | **yes** |
| EEHRxF Document Access Provider (+ Submission Option) | server, MHD documents | no |
| EEHRxF Document Consumer | client, MHD documents | no |
| EEHRxF Document Publisher / Publisher Access Provider | publication | no |

**In scope.** Positive cases for every declared interaction; every **SHALL**
search parameter; the **SHOULD** search parameters where a wrong answer is
clinically consequential; negative must-reject and must-handle cases.

**Out of scope, deliberately.**

- **The document actors and the MHD flows.** A separate plan, and IHE MHD
  already has test material of its own.
- **Profile conformance.** The package carries **one** profile
  (`EehrxfMhdDocumentReference`) and **no examples**, so there is no reference
  dataset to conform to. These are API-contract tests: does the server support
  the interaction it claims, and does the declared parameter actually filter. A
  server can pass every case here and still return clinically wrong content.
- **SMART-on-FHIR authorisation.** `rest.security` declares it, and the `oauth`
  and `jwt` dialects could cover it, but it was excluded from this round.
- **14 of the 25 SHOULD search parameters.** Listed at the foot of the Resource
  Access Provider feature. Covering all 25 would be 62 cases in one file and a
  suite nobody reads; the 11 chosen are dates, codes and statuses, where a
  silently ignored parameter returns a plausible but wrong clinical picture.

## 2. The test cases as authored

### Plan 1 — Resource Access Provider — 54 cases

| Group | Cases | Derived from |
|---|---|---|
| `RAP-R01`–`R12` read | 12 | `<Resource>.interaction:read` [SHALL], one per resource type |
| `RAP-S01`–`S10` search-type | 10 | `<Resource>.interaction:search-type` [SHALL] |
| `RAP-P01`–`P13` search parameters | 13 | every **SHALL** `searchParam` |
| `RAP-P14`–`P24` search parameters | 11 | the consequential **SHOULD** `searchParam`s |
| `RAP-N01`–`N08` negative | 8 | FHIR R4 read/search rules, and the limits of the declaration |

The twelve resource types: Patient, Practitioner, Organization, Condition,
AllergyIntolerance, Observation, DiagnosticReport, MedicationRequest,
MedicationDispense, Immunization, MedicationStatement, Encounter. Practitioner
and Organization declare `read` only, which `RAP-N04` makes explicit.

**Test data is supplied, not generated.** The package has no examples, so the
operator provides one patient and the ids of resources that exist on the server.
That keeps the suite runnable against any deployment, at the cost of manual
setup — the same trade the IUA suite makes.

**Four cases rest on an operator's judgement**, each for a stated reason:
`RAP-P06` and `RAP-P15` because confirming a filter actually filtered needs a
comparison the language cannot make; `RAP-N03` because FHIR allows a server
either to reject an unknown parameter or to ignore it and say so; `RAP-N04` and
`RAP-N08` because the correct behaviour depends on the deployment's access
rules.

### Plan 2 — Resource Consumer — 10 cases

The shape is inverted: the test bed plays the Resource Access Provider, waits to
be called, and asserts on what arrives. Every scenario needs the client
**pointed at the test bed** and then triggered.

| Case | Claim |
|---|---|
| `RC-01` | Issues a conformant read |
| `RC-02` | Issues a search carrying its required `patient` parameter |
| `RC-03` | Asks for a FHIR media type |
| `RC-04` | Handles a searchset with several entries |
| `RC-05` | Follows the `next` link of a paged searchset |
| `RC-06` | Handles an empty searchset without reporting an error |
| `RC-07` | Does not retry a 404 |
| `RC-08` | Surfaces the OperationOutcome diagnostics |
| `RC-09` | Sends only parameters it declares |
| `RC-10` | Requests only resource types it declares |

**Ten cases, not twenty-two.** The CapabilityStatement declares 22 SHALL
interactions, but a client can only be observed doing what it actually does on
the run, and it is not obliged to exercise everything on demand. These cover the
shapes that matter.

**`RC-07` to `RC-10` are the weakest in the suite** and say so beside
themselves. They observe a reaction or an absence, which cannot be settled from
the wire alone, so each ends in an operator's judgement. `RC-10` is weakest of
all: it depends on what the operator happened to trigger, and should be read as
evidence rather than proof.

**Totals.** 64 cases: 54 Resource Access Provider, 10 Resource Consumer. 35 name
a SHALL obligation, 11 a SHOULD, and the rest rest on FHIR R4's own rules.

## 3. What is not yet decided

- **The system under test.** No EU Health Data API implementation is configured.
- **Whether `RC-09` and `RC-10` earn their place.** Both assert an absence over
  a session; if they produce noise in practice, drop them rather than weaken
  what the others claim.
- **Whether the uncovered SHOULDs should be added.** The 14 are listed in the
  feature file; adding them is mechanical if coverage matters more than
  readability.

## 4. Results

**Gate 1 — compilation: met.** 28 October 2026.

```
0 eu-hda-resource-access-provider.feature  [54 test cases]
0 eu-hda-resource-consumer.feature         [10 test cases]

clean: 2, with errors: 0
```

Compiled with `@opentestbed/otb-gherkin` 0.5.0. The generated TDL was checked
beyond the error count: the search URIs build correctly
(`concat($ResourceAccessProviderBase, "/Patient?_id=", $patientId)`), the paged
scenario emits two receives in one transaction and the second asks for `page=2`,
every `btxn` is matched by an `etxn` (10 of each), and there are no backslashes
anywhere (TDL-042).

**Gate 2 — running against a real ITB: NOT MET.**

There is no EU Health Data API implementation configured to measure. **These 64
cases have never been executed. Nothing here is evidence that any implementation
conforms, and nothing here is evidence that the tests themselves pass.**

A clean compile means the sentences were understood — not that the requests are
correct. When an implementation exists, run the suite and expect the negative
cases to need scrutiny: a must-reject case that passes on the first run should
be checked by feeding it something valid and confirming it then fails.
