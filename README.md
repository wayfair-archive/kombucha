# Kombucha

[![Build Status](https://travis-ci.org/wayfair/kombucha.svg?branch=master)](https://travis-ci.org/wayfair/kombucha)

Smart API snapshot testing and linting

## Overview

Kombucha is a command-line program for performing API snapshot testing. The first time Kombucha runs, it executes the HTTP requests you specify and stores the corresponding JSON responses for those requests. These initial responses become the known-good “snapshots” of the API endpoints you are interested in. 

On subsequent runs, Kombucha compares the live response for each endpoint to its corresponding snapshot, and flags differences that it finds problematic. Kombucha is smart enough to know that simple differences in the *values* inside an API response (eg. a value that changed from `true` to `false`, or from `"monday"` to `"tuesday"`) do not constitute breakages of the contract for that API. Instead, Kombucha uses a simple heuristic to determine whether data differences are problematic. 

To put it another way, Kombucha can flag for you when API contracts are broken as endpoints are modified or evolved. However, unlike some other tools, the user does not have to manually specify details of the API contract — Kombucha uses each endpoint’s snapshot as an implicit understanding of the contract.

For details on this computation see [the `structure` check](#the-structure-check).

## Usage

To spin up Kombucha tests for your endpoints, create a configuration file:

### Configuration file

Kombucha’s behavior is governed by a declarative JSON configuration file. This section explains the contents of that file in detail, or you can [jump into the repo](https://github.com/wayfair/kombucha/blob/master/sample.json) and check out a sample configuration file directly.

The top level of the configuration file looks like this:
```json
{
  "userAgent": "kombucha-this-is-a-test-v-0.0001",
  "snaps": [ ... ]
}
```
* `userAgent` is the User Agent string you’d like Kombucha to use when it issues HTTP requests on your behalf
* `snaps` is an array of API endpoints that you would like tested. Here’s what a single entry in the `snaps` array looks like:
```json
{
  ...
  "snaps": [
    {
      "body": { ... },
      "host": "httpbin.org",
      "httpMethod": "GET",
      "httpHeaders": {
        "Accept-Language": "en-US"  
      },
      "path": "/response-headers",
      "queryItems": {
        "foo": "1",
        "bar": "2",
        "baz": "3"
      },
      "scheme": "https",
      "__snapName": "myUniqueSnapName",
      "__snapType": "__REST"
    },
  ...
  ]
}
```
* The `snaps` entry needs to contain the `__snapName` key to uniquely identify the request. This name will be used to create a file with the snap result on disk.
* It is possible to specify any `HTTP` header field with `httpHeaders`  key, the value of a header needs to be a string. This key is not required.
* The `body` key (not required) accepts arbitrary `JSON` and it will be used to set the body if the `HTTP` request.
* `__snapType` specifies the type of request Kombucha is going to issue. The `__REST"` type represents a simple `HTTP` request. The `HTTP` method most be specified with the required `httpMethod` key, use `GET`, `POST`, `PUT`, `DELETE`, `PATCH` or any other methods as the value. The remaining parameters are interpreted accordingly: `queryItems` are converted into key-value pairs and appended onto the `path`, etc.
   * The `snaps` entry above results in an HTTP `GET` to `https://httpbin.org/response-headers?foo=1&bar=2&baz=3`. In addition, Kombucha always sends an `Accept` header of `application/json`.
* Kombucha also supports a `__GRAPHQL` `__snapType` for testing GraphQL endpoints. Documentation for this is forthcoming. 😄

#### Customizing output

When executing a snapshot test, Kombucha converts both the snapshot JSON and the “work” (live response) JSON into data in memory. It then executes what we call [the `structure` check](#the-structure-check) to look for the API breakages and problems discussed above. 

However, with the full JSON data in memory, we can perform other checks on the response as we work. It may be useful to think of this as a built-in “linter” for the response that runs alongside the core snapshotting feature that has previously been described.

The user can add a `__preferences` blob to their configuration file to specify exactly the mixture of checks they’d like to run:
```json
{
  ...
  "snaps": [
    {
      "host": "httpbin.org",
      "httpMethod": "GET",
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
      "__snapName": "myUniqueSnapName",
      "__snapType": "__REST"
    },
  ...
  ]
}
```
* these `__preferences` specify that, in addition to `structure`, the checks named `string-bools` and `string-numbers` should also be run, and if they produce output, that output should be treated as errors, failing the test run. 
   * In addition, the user has requested that the `flag-new-keys` check produce `INFO` level output, and that `array-consistency`, `empty-arrays`, and `empty-objects` be checked, and routed to `WARN` level output.
* any check name (eg. `flag-new-keys`) can be placed at any key (`errors`, `infos`, or `warnings`) in the `__preferences` blob.
* if no `__preferences` are specified, Kombucha runs [the default checks](#default-checks). [See here](#list-of-checks) for the full list of available checks.

### Example output

```
testing: GET: example.org/example - (0 query params)
wrote to: /Users/ptomaselli/Documents/Code/kombucha/__Work__/example.json
['json-path']
    > ERROR: The key new-key does not exist

testing: GET: example.org/example2 - (0 query params)
wrote to: /Users/ptomaselli/Documents/Code/kombucha/__Work__/example2.json
['json-path-2']
    > ERROR: Types didn’t match. Reference: bool(false), test: string("hello world")

testing: GET: example.org/example3 - (3 query params)
wrote to: /Users/ptomaselli/Documents/Code/kombucha/__Work__/example3.json

    > INFO: The key foo exists in the value being tested, but not in the snapshot. Perhaps you need to update your snapshot?

testing: GET: example.org/example4 - (0 query params)
wrote to: /Users/ptomaselli/Documents/Code/kombucha/__Work__/example4.json
finished with errors
```

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

Kombucha performs this check recursively into nested JSON objects as deep as they go, and recursively into the *first element only* of nested JSON arrays, as deep as they go. It doesn’t usually make sense to assert on the length of a JSON array, but for stricter array checking, you can pair the `structure` check with [the `array-consistency` check](#other-checks) to ensure that JSON arrays of any length have the expected type.

### Other checks

* `array-consistency`
   * Kombucha can flag heterogeneous arrays in the work response, since these can be a problem for clients if they are unexpected. We call this the “array consistency” check: Kombucha will check every array in the live response to ensure that the same keys and types are present in items at the indices `[1...]` as are present at index `0`.
* `empty-arrays`
   * more simply, Kombucha can also flag empty arrays (`"key": []`) in the response, as this may also cause problems with clients, or may represent an opportunity to optimize the API.
* `empty-objects`
   * likewise, this check flags empty object literals (`"key": {}`) in the response
* `flag-new-keys`
   * the inverse of the `structure` check: flag JSON keys that appear in the “work” (live response) JSON, but **not** in the snapshot. This may indicate that your snapshot is out of date, or can be used to generate API diffs for endpoints that are under active development.
* `string-bools`
   * flag the values `"true"` and `"false"` (which should probably be `true` and `false` instead)
* `string-numbers`
   * flag, for example, `"99.0"` (as opposed to `99.0`). This check should probably be used sparingly as there are plenty of pseudo-numeric values that nevertheless are best represented as strings (for example: opaque identifiers, or zip codes in the United States)
* `strict-equality`
    * ensure that the `JSON` from the response is exactly the same as the reference on disk.  

### Default checks

If no [`__preferences` are specified](#customizing-output), Kombucha runs with a default series of checks that should be useful for most situations:

* **errors**: `structure`
* **infos**: `empty-arrays`, `empty-objects`, `flag-new-keys`, `string-bools`
* **warnings**: `array-consistency`

## Implementation details / Development / Contributing

Kombucha is written in a functional style and was designed to be easy to extend! We hope to follow up in the future with additional documentation for extending the program, but until then, here is a general idea: 
* JSON is decoded into a [recursive `enum`](https://github.com/wayfair/kombucha/blob/master/Sources/JSONValue/JSONValue.swift#L12) prior to being tested. 
* Check functions are written [in isolation](https://github.com/wayfair/kombucha/blob/master/Sources/JSONCheck/JSONCheck.swift#L153) and [composed at runtime](https://github.com/wayfair/kombucha/blob/master/Sources/KombuchaLib/KombuchaLib.swift#L49), thanks to the magic of [monoids](https://github.com/wayfair/kombucha/blob/master/Sources/JSONCheck/CheckResults.swift#L31). 
* Recursive checks can be written concisely using a generalized [fold](https://github.com/wayfair/kombucha/blob/master/Sources/JSONCheck/JSONValue%2BPrelude.swift#L14) over our JSON data type.

Kombucha was written in-house at [Wayfair](https://github.com/wayfair), but we’d like to thank [Point-Free](https://www.pointfree.co/) for their [`swift-snapshot-testing` library](https://github.com/pointfreeco/swift-snapshot-testing), which we referred to often for hints and prior art, especially w/r/t the ergonomics and user interface of this program.

For a great practical resource on folds in Swift, check out [Swift Talk Episode 152](http://talk.objc.io/episodes/S01E152-processing-commonmark-using-folds).
