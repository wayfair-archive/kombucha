# Kombucha

[![Build Status](https://travis-ci.org/wayfair/kombucha.svg?branch=master)](https://travis-ci.org/wayfair/kombucha)

Smart API snapshot testing and linting

## Overview

Kombucha is a command-line program for performing API snapshot testing. The first time Kombucha runs, it executes the HTTP requests you specify and stores the corresponding JSON responses for those requests. These initial responses become the known-good “snapshots” of the API endpoints you are interested in. 

On subsequent runs, Kombucha compares the live reponse for each endpoint to its corresponding snapshot, and flags differences that it finds problematic. Kombucha is smart enough to know that simple differences in the *values* inside an API response (eg. a value that changed from `true` to `false`, or from `"monday"` to `"tuesday"`) do not constitute breakages of the contract for that API. Instead, Kombucha uses a simple heuristic (for details see [the `structure` check](#the-structure-check)) to determine whether data differences are problematic.

To put it another way, Kombucha can flag for you when API contracts are broken as endpoints are modified or evolved. However, unlike some other tools, the user does not have to manually specify details of the API contract — Kombucha uses each endpoint’s snapshot as an implicit understanding of the contract.

## Usage

To spin up Kombucha tests for your endpoints, first create a configuration file:

### Configuration file

Kombucha’s behavior is governed by a declarative JSON configuration file. This section explains the contents of that file in detail, or you can [jump into the repo](blob/master/sample.json) and check out a sample configuration file directly.

The top level of the configuration file looks like this:
```json
{
  "userAgent": "kombucha-this-is-a-test-v-0.0001",
  "snaps": [ … ]
}
```
* `userAgent` is the User Agent string you’d like Kombucha to use when it issues HTTP requests on your behalf
* `snaps` is an array of API endpoints that you would like tested. Here’s what a single entry in the `snaps` array looks like:
```json
{
  …
  "snaps": [
    {
      "host": "httpbin.org",
      "path": "/response-headers",
      "queryItems": {
        "foo": "1",
        "bar": "2",
        "baz": "3"
      },
      "scheme": "https",
      "__snapType": "__GET"
    },
  …
  ]
}
```
* `__snapType` specifies the type of request Kombucha is going to issue. `__GET` is a simple HTTP `GET` request, and the remaining parameters are interpreted accordingly: `queryItems` are converted into key-value pairs and appended onto the `path` specified, etc.
   * The `snaps` entry above results in an HTTP `GET` to `https://httpbin.org/response-headers?foo=1&bar=2&baz=3`. In addition, Kombucha always sends an `Accept` header of `application/json`.
* Kombucha also supports a `__GRAPHQL` `snapType` for testing GraphQL endpoints. Documentation for this is forthcoming. 😄

#### Customizing output

When executing a snapshot test, Kombucha converts both the snapshot JSON and the “work” (live response) JSON into data in memory. It then executes what we call [the `structure` check](#the-structure-check) to look for the API breakages and problems we’ve discussed above. 

However, with the full JSON data in memory, we can perform other checks on the response as we work. It may be useful to think of this as a built-in “linter” for the response that runs alongside the core snapshotting feature that has previously been described.

The user can add a `__preferences` blob to their configuration file to specify exactly the mixture of checks they’d like to run:
```json
{
  …
  "snaps": [
    {
      "host": "httpbin.org",
      "path": "/response-headers",
      "queryItems": {},
      "scheme": "https",
      "__preferences": {
        "errors": [
          "string-bools",
          "string-numbers",
          "structure"
        ],
        "infos": [
          "flag-new-keys"
        ],
        "warnings": [
          "array-consistency",
          "empty-arrays",
          "empty-objects"
        ]
      },
      "__snapType": "__GET"
    },
  …
  ]
}
```
* the `__preferences` above specify that, in addition to `structure`, the checks named `string-bools` and `string-numbers` should also be run, and if they produce output, that output should be treated as errors, failing the test run. 
   * In addition, the user has requested that the `flag-new-keys` check produce `INFO` level output, and that `array-consistency`, `empty-arrays`, and `empty-objects` be checked, and routed to `WARN` level output.
* any check name (eg. `flag-new-keys`) can be placed at any key (`errors`, `infos`, or `warnings`) in the `__preferences` blob.
* if no `__preferences` are specified, Kombucha runs [the default checks](#default-checks).
* for a complete [list of checks](#list-of-checks), scroll down a bit.

### Example output

⚠️ TODO!

### Command line parameters

* `--print-errors-only` (`-e`): ask Kombucha to omit `INFO` and `WARNING` output when printing to the console. Useful if a set of tests is producing a lot of output and you’d like to “zero in” on the errors only, without having to edit the configuration file
* `--record` (`-r`): ask Kombucha to rewrite all the stored snapshots it knows about. Useful for setting a new baseline for tests or if you know a large amount of the API under test has changed
* `--snapshots-directory` (`-s`): tell Kombucha where to find snapshots for the test run. If not specified, the default is `./__Snapshots/`.
* `--work-directory` (`-w`): tell Kombucha what directory to use as the “work directory” (storage for live responses) for the test run. If not specified, the default is `./__Work__/`.

### Running on macOS

Kombucha is written in [Swift](https://swift.org). If you have a Swift 5 development environment available, you can run Kombucha natively on macOS. To do so, clone this repository, and then run
```
swift build                         # build Kombucha in debug mode
./build/debug/kombucha sample.json  # run the sample tests that are included with this repo
```
To move forward from this point, construct your own JSON configuration file describing your API endpoints and point Kombucha at that file. We suggest storing this configuration file and its snapshots in a git repository separate from this one, so that you can version your usage of Kombucha separately from any versioning of the tool itself. Such an invocation of the tool would look something like:
```
kombucha \
  ../my-tests/kombucha.json \
  --snapshots-directory ../my-tests/__Snapshots__ \
  --work-directory ../my-tests/__Work__
```

### Running via Docker

⚠️ TODO!

## List of checks

### The `structure` check

We call Kombucha’s main snapshotting behavior “the structure check”. With both the snapshot and the work (live response) JSON in memory, Kombucha will flag any JSON keys that appear in the snapshot structure, but not in the work structure. In addition, it will flag any JSON keys where the type of the value in the work structure differs from the type in the snapshot structure (eg. if the key `"foo"` used to have the value `true`, but now it has the value `99.0` or `["hello"]`).

Kombucha performs this check recursively into nested JSON objects as deep as they go, and recursively into the *first element only* of nested JSON arrays, as deep as they go. The lack of coverage for “all” of an array is an issue, but we’re not sure how to solve or improve this yet.

### Other checks

* `array-consistency`
   * on the topic of arrays, Kombucha can flag heterogeneous arrays in the work response, since these can be a problem for clients if they are unexpected. We call this the “array consistency” check: Kombucha will check every array in the live response to ensure that the same keys and types are present in items at the indices `[1...]` as are present at index `0`.
* `empty-arrays`
   * much more simply, Kombucha can also flag empty arrays (`"key": []`) in the response, as this may also cause problems with clients, or may represent an opportunity to optimize the API.
* `empty-objects`
   * likewise, flag empty object literals (`"key": {}`) in the response
* `flag-new-keys`
   * the inverse of the `structure` check: flag JSON keys that appear in the “work” (live response) JSON, but **not** in the snapshot. This may indicate that your snapshot is out of date, or can be used to generate API diffs for endpoints that are under active development.
* `string-bools`
   * flag the values `"true"` and `"false"` (which should probably be `true` and `false` instead)
* `string-numbers`
   * flag, for example, `"99.0"` (as opposed to `99.0`). This check should be used sparingly as there are plenty of pseudo-numeric values that nevertheless are best represented as strings (for example: opaque identifiers, or zip codes in the United States)

### Default checks

If no [`__preferences` are specified](#customizing-output), Kombucha runs with a default series of checks that should be useful for most situations:

* **errors**: `structure`
* **infos**: `empty-arrays`, `empty-objects`, `flag-new-keys`, `string-bools`
* **warnings**: `array-consistency`

## Implementation details / Development / Contributing

⚠️ TODO!
