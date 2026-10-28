# EU Health Data API, hl7.fhir.eu.health-data-api 1.0.0-ballot, FHIR 4.0.1
# https://hl7.eu/fhir/health-data-api/
#
# Actor: EEHRxF Resource Consumer (client).
# CapabilityStatement-EEHRxF-ResourceConsumer declares, per resource type, the
# interactions and search parameters the client must be able to issue.
#
# THE SHAPE IS INVERTED, and that limits what can be claimed. A client
# initiates, so there is nothing to send it: the test bed plays the Resource
# Access Provider, waits to be called, and asserts on what arrives. Three
# consequences:
#
#   1. The client must be POINTED AT THE TEST BED, not at a real server, and
#      then triggered. The operator does that once per run from the endpoint the
#      session prints.
#   2. The server's declaration lists 22 SHALL interactions, but a client can
#      only be observed doing what it actually does on the run. These ten cases
#      cover the shapes that matter, not one case per declared interaction —
#      a client is not obliged to exercise everything on demand.
#   3. FOUR CASES OBSERVE AN ABSENCE OR A REACTION (RC-07 to RC-10). Those are
#      the weakest here and each says so beside itself. Expect them to need an
#      operator's judgement rather than an assertion.
@lang:itb-core-en@^2
Feature: EU Health Data API — Resource Consumer
  The client issues requests the specification allows, and handles the answers
  a conformant server may give.

  Background:
    Given ResourceConsumer is the system under test at "https://client.example.org" as defined by "https://hl7.eu/fhir/health-data-api/CapabilityStatement-EEHRxF-ResourceConsumer.html"
    And ResourceAccessProvider is infrastructure

  # ==================================================================
  # What the client sends
  # ==================================================================

  # RC-01 — Patient.interaction:read [SHALL]. A read is GET on a type and id.
  Scenario: RC-01 the client issues a conformant read
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Point your client at the server address shown for this session, then trigger it to read a single Patient by id."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    Then $received.method should be "GET"
    And $received.path should contain "/Patient/"
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Patient","id":"rc01","active":true}
      """
    And ResourceAccessProvider stops listening for ResourceConsumer

  # RC-02 — Observation.interaction:search-type with search:patient [SHALL].
  # The patient parameter is SHALL, so a conformant client sends it.
  Scenario: RC-02 the client issues a search carrying its required parameter
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger your client to search Observations for a patient."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    Then $received.method should be "GET"
    And $received.path should contain "/Observation"
    And $received.path should contain "patient="
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":0,"entry":[]}
      """
    And ResourceAccessProvider stops listening for ResourceConsumer

  # RC-03 — FHIR R4 §3.1.0.6: a client states the format it wants. Without it a
  # server may answer XML to a client that only reads JSON.
  Scenario: RC-03 the client asks for a FHIR media type
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger any read or search."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    Then $received.headers.Accept should contain "fhir"
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":0,"entry":[]}
      """
    And ResourceAccessProvider stops listening for ResourceConsumer

  # ==================================================================
  # What the client must handle
  # ==================================================================

  # RC-04 — FHIR R4 search: a searchset with several entries. A client that
  # reads only the first entry is a common and silent defect.
  Scenario: RC-04 the client handles a searchset with several entries
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger a search that you expect to return several Conditions."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":3,"entry":[
        {"resource":{"resourceType":"Condition","id":"c1","subject":{"reference":"Patient/p1"}}},
        {"resource":{"resourceType":"Condition","id":"c2","subject":{"reference":"Patient/p1"}}},
        {"resource":{"resourceType":"Condition","id":"c3","subject":{"reference":"Patient/p1"}}}]}
      """
    Then ResourceConsumer confirms each of these is displayed:
      | item                                                     |
      | All three Conditions are presented, not only the first   |
    And ResourceAccessProvider stops listening for ResourceConsumer

  # RC-05 — FHIR R4 §3.1.1: paging. A client that ignores the next link sees a
  # truncated record and cannot tell.
  Scenario: RC-05 the client follows the next link of a paged searchset
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger a search you expect to return many results."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":2,"link":[
        {"relation":"self","url":"http://localhost/Observation?patient=p1"},
        {"relation":"next","url":"http://localhost/Observation?patient=p1&page=2"}],
       "entry":[{"resource":{"resourceType":"Observation","id":"o1","status":"final"}}]}
      """
    And ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    Then $received.path should contain "page=2"
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":2,"entry":[
        {"resource":{"resourceType":"Observation","id":"o2","status":"final"}}]}
      """
    And ResourceAccessProvider stops listening for ResourceConsumer

  # RC-06 — An empty searchset is a valid answer, not an error. A client that
  # treats total 0 as a failure reports a fault that does not exist.
  Scenario: RC-06 the client handles an empty searchset
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger a search for a patient you expect to have no results."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":0,"entry":[]}
      """
    Then ResourceConsumer confirms each of these is displayed:
      | item                                                              |
      | The client reports no results, and does not report an error       |
    And ResourceAccessProvider stops listening for ResourceConsumer

  # ==================================================================
  # Weaker cases — reaction and absence
  #
  # The four below cannot be settled by what arrives on the wire alone. Each
  # ends in an operator judgement, and that is stated rather than disguised as
  # an assertion. If a verdict here matters to you, read the prompt first.
  # ==================================================================

  # RC-07 — A 404 means the resource is not there. Retrying the same request is
  # the defect this case looks for. Note a conformant client may legitimately
  # retry once for an unrelated reason, so the operator judges.
  Scenario: RC-07 the client does not retry a 404
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger a read of a resource id that does not exist."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    And ResourceAccessProvider replies to ResourceConsumer with status 404 and:
      """
      {"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"not-found"}]}
      """
    Then ResourceConsumer confirms each of these is displayed:
      | item                                                                    |
      | The client reported the resource as absent                              |
      | The client did not repeat the same request                              |
    And ResourceAccessProvider stops listening for ResourceConsumer

  # RC-08 — An OperationOutcome carries why. A client that shows only a status
  # code throws away the one thing the server said.
  Scenario: RC-08 the client surfaces an OperationOutcome
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger any request; the server will answer with an error."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    And ResourceAccessProvider replies to ResourceConsumer with status 400 and:
      """
      {"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"invalid",
        "diagnostics":"The search parameter patient is required for this resource type"}]}
      """
    Then ResourceConsumer confirms each of these is displayed:
      | item                                                                 |
      | The diagnostics text from the OperationOutcome reached the user      |
    And ResourceAccessProvider stops listening for ResourceConsumer

  # RC-09 — Asserts an ABSENCE: the client does not send parameters its own
  # CapabilityStatement does not declare. A client sending extra parameters is
  # not strictly non-conformant, which is why this is a judgement and not a
  # failure.
  Scenario: RC-09 the client sends only parameters it declares
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Trigger your most complex search."
    When ResourceAccessProvider receives a request from ResourceConsumer within 120 seconds
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":0,"entry":[]}
      """
    Then ResourceConsumer confirms each of these is displayed:
      | item                                                                        |
      | Every search parameter in the request appears in the client's CapabilityStatement for that resource type |
    And ResourceAccessProvider stops listening for ResourceConsumer

  # RC-10 — Also an absence, over a whole session rather than one request. The
  # weakest case in the suite: it depends on what the operator happened to
  # trigger. Read it as evidence, not proof.
  Scenario: RC-10 the client requests only resource types it declares
    Given ResourceAccessProvider is listening for ResourceConsumer
    And ResourceConsumer is informed "Exercise the client normally for a few minutes, using as many of its features as you can."
    When ResourceAccessProvider receives a request from ResourceConsumer within 300 seconds
    And ResourceAccessProvider replies to ResourceConsumer with status 200 and:
      """
      {"resourceType":"Bundle","type":"searchset","total":0,"entry":[]}
      """
    Then ResourceConsumer confirms each of these is displayed:
      | item                                                                      |
      | Every resource type requested during the session is one the client's CapabilityStatement declares |
      | The session exercised a representative part of the client, not one feature |
    And ResourceAccessProvider stops listening for ResourceConsumer
