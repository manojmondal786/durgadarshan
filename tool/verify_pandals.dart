// Developer-only tool for recording and verifying pandal coordinates in
// assets/data/pandals.json. It is not part of the app and works entirely
// offline: no geocoding, scraping or network access.
//
// Run from the project root:
//   dart run tool/verify_pandals.dart help

import 'dart:io';

import 'src/cli.dart';

void main(List<String> args) {
  exitCode = runVerificationCli(args);
}
