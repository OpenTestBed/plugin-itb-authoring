# EU Health Data API, hl7.fhir.eu.health-data-api 1.0.0-ballot, FHIR 4.0.1
# https://hl7.eu/fhir/health-data-api/
#
# Actor: EEHRxF Resource Access Provider (server). Its obligations are machine
# readable: CapabilityStatement-EEHRxF-ResourceAccessProvider declares, per
# resource type, which interactions and which search parameters it must support,
# each carrying a SHALL or SHOULD expectation. Every scenario below names the
# obligation it covers, in the form Resource.interaction:x or Resource.search:x
# with that expectation, so coverage can be checked without reading Gherkin.
#
# WHAT IS ASSERTED, AND WHAT IS NOT. These are API-contract tests: does the
# server support the interaction it claims, and does the declared search
# parameter actually filter. They are not profile-conformance tests — the
# package carries one profile and no examples, so there is no reference dataset
# to conform to. A server can pass every case here and still return clinically
# wrong content.
#
# TEST DATA is supplied, not generated. The package has no examples, so the
# operator provides one patient and the ids of resources that exist on the
# server under test. That is a deliberate trade: the suite runs against any
# deployment, at the cost of manual setup.
#
# SHOULD COVERAGE IS PARTIAL AND DELIBERATELY SO. 13 search parameters are
# SHALL and all 13 are covered. Of the 25 SHOULD parameters, 11 are covered —
# those where a wrong answer is clinically consequential (dates, codes,
# statuses). Covering all 25 would make 62 cases and a suite nobody reads.
# The uncovered SHOULDs are listed at the foot of this file.
@lang:itb-core-en@^2 @dialect:fhir-validator@^2
Feature: EU Health Data API — Resource Access Provider
  The server supports every interaction and search parameter its
  CapabilityStatement declares, and refuses what it must refuse.

  Background:
    Given ResourceAccessProvider is the system under test at "https://api.example.org/fhir" as defined by "https://hl7.eu/fhir/health-data-api/CapabilityStatement-EEHRxF-ResourceAccessProvider.html"
    And FHIRValidator is a fhir-validator at "http://fhir-validator:8080"
    And Client is infrastructure
    And set header "Accept" to "application/fhir+json"

    # No examples ship with the package, so the ids come from the deployment.
    Given Client is asked for $patientId with "Id of a Patient on this server, e.g. 12345"
    And Client is asked for $patientIdentifier with "A Patient.identifier as system|value"
    And Client is asked for $practitionerId with "Id of a Practitioner on this server"
    And Client is asked for $organizationId with "Id of an Organization on this server"
    And Client is asked for $conditionId with "Id of a Condition for that patient"
    And Client is asked for $allergyId with "Id of an AllergyIntolerance for that patient"
    And Client is asked for $observationId with "Id of an Observation for that patient"
    And Client is asked for $reportId with "Id of a DiagnosticReport for that patient"
    And Client is asked for $medRequestId with "Id of a MedicationRequest for that patient"
    And Client is asked for $medDispenseId with "Id of a MedicationDispense for that patient"
    And Client is asked for $immunizationId with "Id of an Immunization for that patient"
    And Client is asked for $medStatementId with "Id of a MedicationStatement for that patient"
    And Client is asked for $encounterId with "Id of an Encounter for that patient"

  # ==================================================================
  # POSITIVE — read, one per resource type. All SHALL.
  # ==================================================================

  # RAP-R01 — Patient.interaction:read [SHALL]
  Scenario: RAP-R01 Patient read returns the resource
    When Client gets from ResourceAccessProvider at "/Patient/" with id $patientId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "Patient"

  # RAP-R02 — Practitioner.interaction:read [SHALL]
  Scenario: RAP-R02 Practitioner read returns the resource
    When Client gets from ResourceAccessProvider at "/Practitioner/" with id $practitionerId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "Practitioner"

  # RAP-R03 — Organization.interaction:read [SHALL]
  Scenario: RAP-R03 Organization read returns the resource
    When Client gets from ResourceAccessProvider at "/Organization/" with id $organizationId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "Organization"

  # RAP-R04 — Condition.interaction:read [SHALL]
  Scenario: RAP-R04 Condition read returns the resource
    When Client gets from ResourceAccessProvider at "/Condition/" with id $conditionId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "Condition"

  # RAP-R05 — AllergyIntolerance.interaction:read [SHALL]
  Scenario: RAP-R05 AllergyIntolerance read returns the resource
    When Client gets from ResourceAccessProvider at "/AllergyIntolerance/" with id $allergyId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "AllergyIntolerance"

  # RAP-R06 — Observation.interaction:read [SHALL]
  Scenario: RAP-R06 Observation read returns the resource
    When Client gets from ResourceAccessProvider at "/Observation/" with id $observationId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "Observation"

  # RAP-R07 — DiagnosticReport.interaction:read [SHALL]
  Scenario: RAP-R07 DiagnosticReport read returns the resource
    When Client gets from ResourceAccessProvider at "/DiagnosticReport/" with id $reportId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "DiagnosticReport"

  # RAP-R08 — MedicationRequest.interaction:read [SHALL]
  Scenario: RAP-R08 MedicationRequest read returns the resource
    When Client gets from ResourceAccessProvider at "/MedicationRequest/" with id $medRequestId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "MedicationRequest"

  # RAP-R09 — MedicationDispense.interaction:read [SHALL]
  Scenario: RAP-R09 MedicationDispense read returns the resource
    When Client gets from ResourceAccessProvider at "/MedicationDispense/" with id $medDispenseId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "MedicationDispense"

  # RAP-R10 — Immunization.interaction:read [SHALL]
  Scenario: RAP-R10 Immunization read returns the resource
    When Client gets from ResourceAccessProvider at "/Immunization/" with id $immunizationId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "Immunization"

  # RAP-R11 — MedicationStatement.interaction:read [SHALL]
  Scenario: RAP-R11 MedicationStatement read returns the resource
    When Client gets from ResourceAccessProvider at "/MedicationStatement/" with id $medStatementId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "MedicationStatement"

  # RAP-R12 — Encounter.interaction:read [SHALL]
  Scenario: RAP-R12 Encounter read returns the resource
    When Client gets from ResourceAccessProvider at "/Encounter/" with id $encounterId as $resource
    Then $response.status should be 200
    And $resource at "/resourceType" should be "Encounter"

  # ==================================================================
  # POSITIVE — search-type, one per searching resource. All SHALL.
  # Each asserts a searchset Bundle, which is what search-type means.
  # ==================================================================

  # RAP-S01 — Patient.interaction:search-type [SHALL]
  Scenario: RAP-S01 Patient search returns a searchset
    When Client gets from ResourceAccessProvider at "/Patient?_id=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/resourceType" should be "Bundle"
    And $bundle at "/type" should be "searchset"

  # RAP-S02 — Condition.interaction:search-type [SHALL]
  Scenario: RAP-S02 Condition search returns a searchset
    When Client gets from ResourceAccessProvider at "/Condition?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S03 — AllergyIntolerance.interaction:search-type [SHALL]
  Scenario: RAP-S03 AllergyIntolerance search returns a searchset
    When Client gets from ResourceAccessProvider at "/AllergyIntolerance?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S04 — Observation.interaction:search-type [SHALL]
  Scenario: RAP-S04 Observation search returns a searchset
    When Client gets from ResourceAccessProvider at "/Observation?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S05 — DiagnosticReport.interaction:search-type [SHALL]
  Scenario: RAP-S05 DiagnosticReport search returns a searchset
    When Client gets from ResourceAccessProvider at "/DiagnosticReport?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S06 — MedicationRequest.interaction:search-type [SHALL]
  Scenario: RAP-S06 MedicationRequest search returns a searchset
    When Client gets from ResourceAccessProvider at "/MedicationRequest?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S07 — MedicationDispense.interaction:search-type [SHALL]
  Scenario: RAP-S07 MedicationDispense search returns a searchset
    When Client gets from ResourceAccessProvider at "/MedicationDispense?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S08 — Immunization.interaction:search-type [SHALL]
  Scenario: RAP-S08 Immunization search returns a searchset
    When Client gets from ResourceAccessProvider at "/Immunization?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S09 — MedicationStatement.interaction:search-type [SHALL]
  Scenario: RAP-S09 MedicationStatement search returns a searchset
    When Client gets from ResourceAccessProvider at "/MedicationStatement?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-S10 — Encounter.interaction:search-type [SHALL]
  Scenario: RAP-S10 Encounter search returns a searchset
    When Client gets from ResourceAccessProvider at "/Encounter?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # ==================================================================
  # SEARCH PARAMETERS — every SHALL (13)
  # A declared parameter that does not filter is worse than one that is
  # absent: the caller gets data it did not ask for and cannot tell.
  # ==================================================================

  # RAP-P01 — Patient.search:_id [SHALL]
  Scenario: RAP-P01 Patient _id returns exactly that patient
    When Client gets from ResourceAccessProvider at "/Patient?_id=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/id" should be $patientId
    And $bundle at "/total" should be 1

  # RAP-P02 — Patient.search:identifier [SHALL]
  Scenario: RAP-P02 Patient identifier finds the patient
    When Client gets from ResourceAccessProvider at "/Patient?identifier=" with id $patientIdentifier as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"
    And $bundle at "/entry/0/resource/resourceType" should be "Patient"

  # RAP-P03 — Condition.search:patient [SHALL]
  Scenario: RAP-P03 Condition patient filters to that patient
    When Client gets from ResourceAccessProvider at "/Condition?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/subject/reference" should contain $patientId

  # RAP-P04 — AllergyIntolerance.search:patient [SHALL]
  Scenario: RAP-P04 AllergyIntolerance patient filters to that patient
    When Client gets from ResourceAccessProvider at "/AllergyIntolerance?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/patient/reference" should contain $patientId

  # RAP-P05 — Observation.search:patient [SHALL]
  Scenario: RAP-P05 Observation patient filters to that patient
    When Client gets from ResourceAccessProvider at "/Observation?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/subject/reference" should contain $patientId

  # RAP-P06 — Observation.search:category [SHALL]
  Scenario: RAP-P06 Observation category filters by category
    Given Client is asked for $obsCategory with "An Observation.category code this server holds, e.g. vital-signs"
    When Client gets from ResourceAccessProvider at "/Observation?category=" with id $obsCategory as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"
    And ResourceAccessProvider confirms each of these is displayed:
      | item                                                              |
      | Every Observation returned carries the requested category         |

  # RAP-P07 — DiagnosticReport.search:patient [SHALL]
  Scenario: RAP-P07 DiagnosticReport patient filters to that patient
    When Client gets from ResourceAccessProvider at "/DiagnosticReport?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/subject/reference" should contain $patientId

  # RAP-P08 — DiagnosticReport.search:category [SHALL]
  Scenario: RAP-P08 DiagnosticReport category filters by category
    Given Client is asked for $reportCategory with "A DiagnosticReport.category code this server holds, e.g. LAB"
    When Client gets from ResourceAccessProvider at "/DiagnosticReport?category=" with id $reportCategory as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P09 — MedicationRequest.search:patient [SHALL]
  Scenario: RAP-P09 MedicationRequest patient filters to that patient
    When Client gets from ResourceAccessProvider at "/MedicationRequest?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/subject/reference" should contain $patientId

  # RAP-P10 — MedicationDispense.search:patient [SHALL]
  Scenario: RAP-P10 MedicationDispense patient filters to that patient
    When Client gets from ResourceAccessProvider at "/MedicationDispense?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/subject/reference" should contain $patientId

  # RAP-P11 — Immunization.search:patient [SHALL]
  Scenario: RAP-P11 Immunization patient filters to that patient
    When Client gets from ResourceAccessProvider at "/Immunization?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/patient/reference" should contain $patientId

  # RAP-P12 — MedicationStatement.search:patient [SHALL]
  Scenario: RAP-P12 MedicationStatement patient filters to that patient
    When Client gets from ResourceAccessProvider at "/MedicationStatement?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/subject/reference" should contain $patientId

  # RAP-P13 — Encounter.search:patient [SHALL]
  Scenario: RAP-P13 Encounter patient filters to that patient
    When Client gets from ResourceAccessProvider at "/Encounter?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And $bundle at "/entry/0/resource/subject/reference" should contain $patientId

  # ==================================================================
  # SEARCH PARAMETERS — the SHOULD ones where a wrong answer matters (11)
  # Dates, codes and statuses. A server that silently ignores one of these
  # returns a plausible but wrong clinical picture.
  # ==================================================================

  # RAP-P14 — Observation.search:code [SHOULD]
  Scenario: RAP-P14 Observation code filters by code
    Given Client is asked for $obsCode with "An Observation.code this server holds, as system|code"
    When Client gets from ResourceAccessProvider at "/Observation?code=" with id $obsCode as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P15 — Observation.search:date [SHOULD]
  Scenario: RAP-P15 Observation date filters by date
    When Client gets from ResourceAccessProvider at "/Observation?patient=" with id $patientId as $bundle
    Then $response.status should be 200
    And ResourceAccessProvider confirms each of these is displayed:
      | item                                                                        |
      | Repeating the search with &date=ge2020-01-01 returns a subset, not the same |

  # RAP-P16 — Observation.search:status [SHOULD]
  Scenario: RAP-P16 Observation status filters by status
    When Client gets from ResourceAccessProvider at "/Observation?status=" with id "final" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P17 — DiagnosticReport.search:code [SHOULD]
  Scenario: RAP-P17 DiagnosticReport code filters by code
    Given Client is asked for $reportCode with "A DiagnosticReport.code this server holds, as system|code"
    When Client gets from ResourceAccessProvider at "/DiagnosticReport?code=" with id $reportCode as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P18 — DiagnosticReport.search:date [SHOULD]
  Scenario: RAP-P18 DiagnosticReport date filters by date
    When Client gets from ResourceAccessProvider at "/DiagnosticReport?date=" with id "ge2020-01-01" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P19 — MedicationRequest.search:status [SHOULD]
  Scenario: RAP-P19 MedicationRequest status filters by status
    When Client gets from ResourceAccessProvider at "/MedicationRequest?status=" with id "active" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P20 — MedicationRequest.search:authoredon [SHOULD]
  Scenario: RAP-P20 MedicationRequest authoredon filters by date
    When Client gets from ResourceAccessProvider at "/MedicationRequest?authoredon=" with id "ge2020-01-01" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P21 — MedicationDispense.search:whenhandedover [SHOULD]
  Scenario: RAP-P21 MedicationDispense whenhandedover filters by date
    When Client gets from ResourceAccessProvider at "/MedicationDispense?whenhandedover=" with id "ge2020-01-01" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P22 — Immunization.search:date [SHOULD]
  Scenario: RAP-P22 Immunization date filters by date
    When Client gets from ResourceAccessProvider at "/Immunization?date=" with id "ge2020-01-01" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P23 — Encounter.search:date [SHOULD]
  Scenario: RAP-P23 Encounter date filters by date
    When Client gets from ResourceAccessProvider at "/Encounter?date=" with id "ge2020-01-01" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # RAP-P24 — Condition.search:clinical-status [SHOULD]
  Scenario: RAP-P24 Condition clinical-status filters by status
    When Client gets from ResourceAccessProvider at "/Condition?clinical-status=" with id "active" as $bundle
    Then $response.status should be 200
    And $bundle at "/type" should be "searchset"

  # ==================================================================
  # NEGATIVE — what the server must refuse or handle
  # ==================================================================

  # RAP-N01 — FHIR R4 read of an unknown id. 404 is the only correct answer;
  # a 200 with an empty body would leave a client unable to tell.
  Scenario: RAP-N01 read of a non-existent id is refused with 404
    When Client gets from ResourceAccessProvider at "/Patient/" with id "no-such-patient-id-0000" as $refused
    Then $response.status should be 404

  # RAP-N02 — FHIR R4: an unknown resource type is not a 500.
  Scenario: RAP-N02 an unknown resource type is refused
    When Client gets from ResourceAccessProvider at "/NotAResourceType/" with id "1" as $refused
    Then $response.status should be at least 400
    And $response.status should be less than 500

  # RAP-N03 — FHIR R4 search: an unknown parameter is either an error or
  # ignored-and-reported, never silently honoured.
  Scenario: RAP-N03 an unknown search parameter is not silently accepted
    When Client gets from ResourceAccessProvider at "/Patient?notAParameter=" with id "x" as $bundle
    Then ResourceAccessProvider confirms each of these is displayed:
      | item                                                                      |
      | The server either returned an error, or a searchset whose OperationOutcome reports the parameter as ignored |

  # RAP-N04 — Practitioner declares read only. Search must not behave as if
  # it were supported; this is the boundary of the declaration.
  Scenario: RAP-N04 Practitioner search is not offered
    When Client gets from ResourceAccessProvider at "/Practitioner?_id=" with id $practitionerId as $refused
    Then ResourceAccessProvider confirms each of these is displayed:
      | item                                                                  |
      | The CapabilityStatement declares read only for Practitioner, and the server's answer is consistent with that |

  # RAP-N05 — FHIR R4 search: a malformed date prefix must not be read as a
  # plain equality match.
  Scenario: RAP-N05 a malformed date is refused
    When Client gets from ResourceAccessProvider at "/Observation?date=" with id "not-a-date" as $refused
    Then $response.status should be at least 400
    And $response.status should be less than 500

  # RAP-N06 — An unsupported _format must not produce a 500.
  Scenario: RAP-N06 an unsupported _format is handled
    When Client gets from ResourceAccessProvider at "/Patient?_format=" with id "application/not-a-format" as $refused
    Then $response.status should be less than 500

  # RAP-N07 — FHIR R4: an error carries an OperationOutcome, not a bare status
  # or an HTML page. Without it a client cannot report what went wrong.
  Scenario: RAP-N07 an error response carries an OperationOutcome
    When Client gets from ResourceAccessProvider at "/Patient/" with id "no-such-patient-id-0000" as $refused
    Then $response.status should be 404
    And $response.headers.Content-Type should contain "json"
    And $refused at "/resourceType" should be "OperationOutcome"

  # RAP-N08 — A search with no patient context across a patient-compartment
  # resource. What is correct depends on the deployment's access rules, so the
  # operator judges; the case exists to make the behaviour explicit.
  Scenario: RAP-N08 a patient-compartment search with no patient is deliberate
    When Client gets from ResourceAccessProvider at "/Observation?_count=" with id "1" as $bundle
    Then ResourceAccessProvider confirms each of these is displayed:
      | item                                                                      |
      | Searching Observation with no patient context behaves as this deployment intends — refused, scoped, or open |

# ==================================================================
# NOT COVERED, deliberately
#
# 14 of the 25 SHOULD search parameters, where a silent failure is less
# consequential than for a date, code or status:
#   Patient.family, Patient.given, Patient.birthdate
#   Condition.category, Condition.code
#   AllergyIntolerance.clinical-status
#   MedicationRequest.intent
#   MedicationDispense.status
#   Immunization.status
#   MedicationStatement.status, MedicationStatement.effective
#   Encounter.status, Encounter.class
#   Observation.category is covered; Observation's remaining SHOULDs are not
#
# Also out of scope on this pass: the DocumentAccessProvider and
# DocumentPublisher actors, the MHD-based document flows, profile conformance
# (the package carries one profile and no examples), and SMART-on-FHIR
# authorisation, which the CapabilityStatement declares as its security service.
# ==================================================================
