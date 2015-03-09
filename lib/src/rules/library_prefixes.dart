// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.library_prefixes;

import 'package:analyzer/src/generated/ast.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/util.dart';

const desc = r'DO use `lowercase_with_underscores` when specifying a library prefix.';

const details = r'''
**DO** use `lowercase_with_underscores` when specifying a library prefix.

**GOOD:**

```
import 'dart:math' as math;
import 'dart:json' as json;
import 'package:js/js.dart' as js;
import 'package:javascript_utils/javascript_utils.dart' as js_utils;
```

**BAD:**

```
import 'dart:math' as Math;
import 'dart:json' as JSON;
import 'package:js/js.dart' as JS;
import 'package:javascript_utils/javascript_utils.dart' as jsUtils;
```
''';

class LibraryPrefixes extends LintRule {
  LibraryPrefixes() : super(
          name: 'library_prefixes',
          description: desc,
          details: details,
          group: Group.STYLE_GUIDE,
          kind: Kind.AVOID);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitImportDirective(ImportDirective node) {
    if (node.prefix != null && !isLowerCaseUnderScore(node.prefix.toString())) {
      rule.reportLint(node.prefix);
    }
  }


}
