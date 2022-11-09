// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'utils/io_utils.dart' show computeRepoDirUri;

void main(List<String> args) {
  final Uri repoDir = computeRepoDirUri();
  String generated = generateTestParser(repoDir);
  new File.fromUri(computeTestParserUri(repoDir))
      .writeAsStringSync(generated, flush: true);
}

Uri computeTestParserUri(Uri repoDir) {
  return repoDir.resolve("pkg/front_end/test/parser_test_parser.dart");
}

String generateTestParser(Uri repoDir) {
  StringBuffer out = new StringBuffer();
  File f = new File.fromUri(repoDir
      .resolve("pkg/_fe_analyzer_shared/lib/src/parser/parser_impl.dart"));
  List<int> rawBytes = f.readAsBytesSync();

  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  Utf8BytesScanner scanner = new Utf8BytesScanner(bytes, includeComments: true);
  Token firstToken = scanner.tokenize();

  out.write(r"""
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/assert.dart';
import 'package:_fe_analyzer_shared/src/parser/block_kind.dart';
import 'package:_fe_analyzer_shared/src/parser/constructor_reference_context.dart';
import 'package:_fe_analyzer_shared/src/parser/declaration_kind.dart';
import 'package:_fe_analyzer_shared/src/parser/directive_context.dart';
import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart';
import 'package:_fe_analyzer_shared/src/parser/listener.dart' show Listener;
import 'package:_fe_analyzer_shared/src/parser/member_kind.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;
import 'package:_fe_analyzer_shared/src/parser/parser_impl.dart' show AwaitOrYieldContext;
import 'package:_fe_analyzer_shared/src/parser/token_stream_rewriter.dart';
import 'package:_fe_analyzer_shared/src/parser/type_info.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/fasta/fasta_codes.dart' as codes;
import 'package:front_end/src/fasta/source/diet_parser.dart'
    show useImplicitCreationExpressionInCfe;

// THIS FILE IS AUTO GENERATED BY 'test/parser_test_parser_creator.dart'
// Run this command to update it:
// 'dart pkg/front_end/test/parser_test_parser_creator.dart'

class TestParser extends Parser {
  int indent = 0;
  StringBuffer sb = new StringBuffer();
  final bool trace;

  TestParser(Listener listener, this.trace, {required bool allowPatterns})
      : super(listener,
            useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
            allowPatterns: allowPatterns);

  String createTrace() {
    List<String> traceLines = StackTrace.current.toString().split("\n");
    for (int i = 0; i < traceLines.length; i++) {
      // Find first one that's not any of the denylisted ones.
      String line = traceLines[i];
      if (line.contains("parser_test_listener.dart:") ||
          line.contains("parser_suite.dart:") ||
          line.contains("parser_test_parser.dart:") ||
          line == "<asynchronous suspension>") continue;
      return line.substring(line.indexOf("(") + 1, line.lastIndexOf(")"));
    }
    return "N/A";
  }

  void doPrint(String s) {
    String traceString = "";
    if (trace) traceString = " (${createTrace()})";
    sb.writeln(("  " * indent) + s + traceString);
  }

""");

  ParserCreatorListener listener = new ParserCreatorListener(out);
  ClassMemberParser parser = new ClassMemberParser(listener);
  parser.parseUnit(firstToken);

  out.writeln("}");

  return new DartFormatter().format("$out");
}

class ParserCreatorListener extends Listener {
  final StringSink out;
  bool insideParserClass = false;
  String? currentMethodName;
  List<String> parameters = [];
  List<String?> parametersNamed = [];

  ParserCreatorListener(this.out);

  @override
  void beginClassDeclaration(
      Token begin,
      Token? abstractToken,
      Token? macroToken,
      Token? viewToken,
      Token? sealedToken,
      Token? augmentToken,
      Token name) {
    if (name.lexeme == "Parser") insideParserClass = true;
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    insideParserClass = false;
  }

  @override
  void beginMethod(
      DeclarationKind declarationKind,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    currentMethodName = name.lexeme;
  }

  @override
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    parameters.clear();
    parametersNamed.clear();
    currentMethodName = null;
  }

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    if (insideParserClass && !currentMethodName!.startsWith("_")) {
      Token token = beginToken;
      Token? latestToken;
      out.writeln("  @override");
      out.write("  ");
      while (true) {
        if (troubleParameterTokens.containsKey(token)) {
          if (latestToken != null && latestToken.charEnd < token.charOffset) {
            out.write(" ");
          }
          out.write("dynamic");
          token = troubleParameterTokens[token]!;
        }
        if (latestToken != null && latestToken.charEnd < token.charOffset) {
          out.write(" ");
        }
        if (token is SimpleToken && token.type == TokenType.FUNCTION) {
          // Don't write out the '=>'.
          out.write("{");
          break;
        }
        out.write(token.lexeme);
        if (token is BeginToken &&
            token.type == TokenType.OPEN_CURLY_BRACKET &&
            (beginParam.endGroup == endToken ||
                token.charOffset > beginParam.endGroup!.charOffset)) {
          break;
        }
        if (token == endToken) {
          throw token.runtimeType;
        }
        latestToken = token;
        token = token.next!;
      }

      out.write("\n    ");
      out.write("doPrint('$currentMethodName(");
      String separator = "";
      for (int i = 0; i < parameters.length; i++) {
        out.write(separator);
        out.write(r"' '$");
        out.write(parameters[i]);
        separator = ", ";
      }
      for (int i = 0; i < parametersNamed.length; i++) {
        out.write(separator);
        out.write("' '");
        out.write(parametersNamed[i]);
        out.write(r": $");
        out.write(parametersNamed[i]);
        separator = ", ";
      }
      out.write(")');\n    ");

      out.write("indent++;\n    ");
      out.write("var result = super.$currentMethodName");
      if (getOrSet != null && getOrSet.lexeme == "get") {
        // no parens
        out.write(";\n    ");
      } else {
        out.write("(");
        String separator = "";
        for (int i = 0; i < parameters.length; i++) {
          out.write(separator);
          out.write(parameters[i]);
          separator = ", ";
        }
        for (int i = 0; i < parametersNamed.length; i++) {
          out.write(separator);
          out.write(parametersNamed[i]);
          out.write(": ");
          out.write(parametersNamed[i]);
          separator = ", ";
        }
        out.write(");\n    ");
      }
      out.write("indent--;\n    ");
      out.write("return result;\n  ");
      out.write("}");
      out.write("\n\n");
    }
    parameters.clear();
    parametersNamed.clear();
    currentMethodName = null;
  }

  int formalParametersNestLevel = 0;
  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    formalParametersNestLevel++;
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    formalParametersNestLevel--;
  }

  Token? currentFormalParameterToken;

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {
    if (formalParametersNestLevel == 1) {
      currentFormalParameterToken = token;
    }
  }

  Map<Token?, Token?> troubleParameterTokens = {};

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    if (formalParametersNestLevel > 0 && token.lexeme.startsWith("_")) {
      troubleParameterTokens[currentFormalParameterToken] = null;
    }
  }

  @override
  void endFormalParameter(
      Token? thisKeyword,
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    if (formalParametersNestLevel != 1) {
      return;
    }
    if (troubleParameterTokens.containsKey(currentFormalParameterToken)) {
      troubleParameterTokens[currentFormalParameterToken] = nameToken;
    }
    currentFormalParameterToken = null;
    if (kind == FormalParameterKind.optionalNamed) {
      parametersNamed.add(nameToken.lexeme);
    } else {
      parameters.add(nameToken.lexeme);
    }
  }
}
