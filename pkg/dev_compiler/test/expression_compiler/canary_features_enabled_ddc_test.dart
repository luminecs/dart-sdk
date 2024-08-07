// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;

import '../shared_test_options.dart';
import 'canary_features_enabled_common.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  final driver = await ExpressionEvaluationTestDriver.init();
  final setup =
      SetupCompilerOptions(moduleFormat: ModuleFormat.ddc, args: args);
  final mode = setup.canaryFeatures ? 'canary' : 'stable';
  runTests(driver, setup, mode);
}
