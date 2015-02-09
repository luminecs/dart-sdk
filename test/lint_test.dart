// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_lint.test.lint_test;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:dart_lint/src/io.dart';
import 'package:dart_lint/src/linter.dart';
import 'package:dart_lint/src/rules.dart';
import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';

import '../bin/lint.dart' as dartlint;

const String ruleDir = 'test/rules';

/// Linter engine tests
void defineLinterEngineTests() {
  group('engine', () {
    group('reporter', () {
      _test(String label, String expected, report(PrintingReporter r)) {
        test(label, () {
          String msg;
          PrintingReporter reporter = new PrintingReporter((m) => msg = m);
          report(reporter);
          expect(msg, expected);
        });
      }
      _test('exception', 'EXCEPTION: LinterException: foo',
          (r) => r.exception(new LinterException('foo')));
      _test('logError', 'ERROR: foo', (r) => r.logError('foo'));
      _test('logError2', 'ERROR: foo',
          (r) => r.logError2('foo', new Exception()));
      _test('logInformation', 'INFO: foo', (r) => r.logInformation('foo'));
      _test('logInformation2', 'INFO: foo',
          (r) => r.logInformation2('foo', new Exception()));
      _test('warn', 'WARN: foo', (r) => r.warn('foo'));
    });

    group('exceptions', () {
      test('message', () {
        expect(const LinterException('foo').message, equals('foo'));
      });
      test('toString', () {
        expect(const LinterException().toString(), equals('LinterException'));
        expect(const LinterException('foo').toString(),
            equals('LinterException: foo'));
      });
    });

    group('camel case', () {
      test('humanize', () {
        expect(new CamelCaseString('FooBar').humanized, equals('Foo Bar'));
        expect(new CamelCaseString('Foo').humanized, equals('Foo'));
      });
      test('validation', () {
        expect(() => new CamelCaseString('foo'),
            throwsA(new isInstanceOf<ArgumentError>()));
      });
    });

    group('groups', () {
      test('factory', () {
        expect(new Group('Style Guide').custom, isFalse);
        expect(new Group('Styleguide').custom, isFalse);
        expect(new Group('Kustom').custom, isTrue);
      });
    });

    group('kinds', () {
      test('factory', () {
        var kinds = ['DO', 'DONT', "DON'T", 'AVOID', 'PREFER', 'CONSIDER'];
        kinds.map((n) => new Kind(n)).forEach((k) => expect(k.custom, isFalse));
      });
    });

    group('lint driver', () {
      test('basic', () {
        bool visited;
        var options =
            new LinterOptions(() => [new MockLinter((n) => visited = true)]);
        new SourceLinter(options).lintLibrarySource(
            libraryName: 'testLibrary',
            libraryContents: 'library testLibrary;');
        expect(visited, isTrue);
      });
    });

    group('main', () {
      setUp(() => exitCode = 0);
      tearDown(() => exitCode = 0);
      test('smoke', () {
        FileSystemEntity firstRuleTest =
            new Directory(ruleDir).listSync().firstWhere((f) => isDartFile(f));
        dartlint.main([firstRuleTest.path]);
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('no args', () {
        dartlint.main([]);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
      test('help', () {
        dartlint.main(['-h']);
        // Help shouldn't generate an error code
        expect(dartlint.isLinterErrorCode(exitCode), isFalse);
      });
      test('unknown arg', () {
        dartlint.main(['-XXXXX']);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
      test('bad path', () {
        var badPath = new Directory(ruleDir).path + '/___NonExistent.dart';
        dartlint.main([badPath]);
        expect(exitCode, equals(dartlint.unableToProcessExitCode));
      });
    });

    group('io', () {
      test('link', () {
        Link l = new Link('bogus');
        expect(processFile(l), isFalse);
      });
      test('bad extension', () {
        File f = new File('bogus.txt');
        expect(processFile(f), isFalse);
      });
    });
  });
}

/// Rule tests
void defineRuleTests() {

  //TODO: if ruleDir cannot be found print message to set CWD to project root
  group('rule', () {
    for (var entry in new Directory(ruleDir).listSync()) {
      if (entry is! File || !isDartFile(entry)) continue;
      var ruleName = p.basenameWithoutExtension(entry.path);
      testRule(ruleName, entry);
    }
  });
}

/// Test framework sanity
void defineSanityTests() {
  group('test framework', () {
    group('annotation', () {
      test('extraction', () {
        expect(extractAnnotation('int x; // LINT'), isNotNull);
        expect(extractAnnotation('int x; //LINT'), isNotNull);
        expect(extractAnnotation('int x; // OK'), isNull);
        expect(extractAnnotation('int x;'), isNull);
        expect(extractAnnotation('dynamic x; // LINT dynamic is bad').message,
            equals('dynamic is bad'));
        expect(extractAnnotation('dynamic x; //LINT').message, isNull);
        expect(extractAnnotation('dynamic x; //LINT ').message, isNull);
      });
    });
    test('equality', () {
      expect(
          new Annotation('Actual message (to be ignored)', ErrorType.LINT, 1),
          matchesAnnotation(null, ErrorType.LINT, 1));
      expect(new Annotation('Message', ErrorType.LINT, 1),
          matchesAnnotation('Message', ErrorType.LINT, 1));
    });
    test('inequality', () {
      expect(() => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.HINT, 1)),
          throwsA(new isInstanceOf<TestFailure>()));
      expect(() => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message2', ErrorType.LINT, 1)),
          throwsA(new isInstanceOf<TestFailure>()));
      expect(() => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.LINT, 2)),
          throwsA(new isInstanceOf<TestFailure>()));
    });
  });
}

Annotation extractAnnotation(String line) {
  int index = line.indexOf(new RegExp(r'//[ ]?LINT'));
  if (index > -1) {
    int msgIndex = line.substring(index).indexOf('T') + 1;
    String msg = null;
    if (msgIndex < line.length) {
      msg = line.substring(index + msgIndex).trim();
      if (msg.length == 0) {
        msg = null;
      }
    }
    return new Annotation.forLint(msg);
  }
  return null;
}

main() {
  groupSep = ' | ';

  defineSanityTests();
  defineLinterEngineTests();
  defineRuleTests();
}

AnnotationMatcher matchesAnnotation(
    String message, ErrorType type, int lineNumber) =>
        new AnnotationMatcher(new Annotation(message, type, lineNumber));

void testRule(String ruleName, File file) {
  test('$ruleName', () {
    var expected = <AnnotationMatcher>[];

    int lineNumber = 1;
    for (var line in file.readAsLinesSync()) {
      var annotation = extractAnnotation(line);
      if (annotation != null) {
        annotation.lineNumber = lineNumber;
        expected.add(new AnnotationMatcher(annotation));
      }
      ++lineNumber;
    }

    DartLinter driver = new DartLinter.forRules(
        () => [ruleMap[ruleName]].where((rule) => rule != null));

    Iterable<AnalysisErrorInfo> lints = driver.lintFile(file);

    List<Annotation> actual = [];
    lints.forEach((AnalysisErrorInfo info) {
      info.errors.forEach((AnalysisError error) {
        actual.add(new Annotation.forError(error, info.lineInfo));
      });
    });
    expect(actual, unorderedMatches(expected));
  });
}

typedef nodeVisitor(AstNode node);

typedef AstVisitor VisitorCallback();

class Annotation {
  final String message;
  final ErrorType type;
  int lineNumber;

  Annotation(this.message, this.type, this.lineNumber);

  Annotation.forError(AnalysisError error, LineInfo lineInfo) : this(
          error.message, error.errorCode.type,
          lineInfo.getLocation(error.offset).lineNumber);

  Annotation.forLint([String message]) : this(message, ErrorType.LINT, null);

  String toString() => '[$type]: "$message" (line: $lineNumber)';

  static Iterable<Annotation> fromErrors(AnalysisErrorInfo error) {
    List<Annotation> annotations = [];
    error.errors.forEach(
        (e) => annotations.add(new Annotation.forError(e, error.lineInfo)));
    return annotations;
  }
}

class AnnotationMatcher extends Matcher {
  final Annotation _expected;
  AnnotationMatcher(this._expected);

  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  bool matches(item, Map matchState) {
    return item is Annotation && _matches(item as Annotation);
  }

  bool _matches(Annotation other) {
    // Only test messages if they're specified in the expectation
    if (_expected.message != null) {
      if (_expected.message != other.message) {
        return false;
      }
    }
    return _expected.type == other.type &&
        _expected.lineNumber == other.lineNumber;
  }
}

class MockLinter extends LintRule {
  VisitorCallback visitorCallback;

  MockLinter([nodeVisitor v]) : super(
          name: 'MockLint',
          group: Group.STYLE_GUIDE,
          kind: Kind.AVOID,
          description: 'Desc',
          details: 'And so on...') {
    visitorCallback = () => new MockVisitor(v);
  }

  @override
  AstVisitor getVisitor() => visitorCallback();
}

class MockVisitor extends GeneralizingAstVisitor {
  final nodeVisitor;

  MockVisitor(this.nodeVisitor);

  visitNode(AstNode node) {
    if (nodeVisitor != null) {
      nodeVisitor(node);
    }
  }
}
