// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Use `=` to separate a named parameter from its default value.';

const _details = r'''
NOTE: This rule is removed in Dart 3.0; it is no longer functional.

**DO** use `=` to separate a named parameter from its default value.

**BAD:**
```dart
m({a: 1})
```

**GOOD:**
```dart
m({a = 1})
```

''';

class PreferEqualForDefaultValues extends LintRule {
  PreferEqualForDefaultValues()
      : super(
            name: 'prefer_equal_for_default_values',
            description: _desc,
            details: _details,
            state: State.removed(since: dart3),
            categories: {LintRuleCategory.style});

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
