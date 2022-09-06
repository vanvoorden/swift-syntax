//===------------------ OperatorPrecedence.swift --------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
import SwiftSyntax

/// Maintains and validates information about all operators in a Swift program.
///
/// The operator table keep track of the various operator and precedence group
/// declarations within a program. Its core operations involve processing the
/// operator and precedence group declarations from a source tree into a
/// semantic representation, validating the correctness of those declarations,
/// and "folding" sequence expression syntax into a structured expression
/// syntax tree.
public struct OperatorTable {
  var precedenceGraph: PrecedenceGraph = .init()
  var infixOperators: [OperatorName : Operator] = [:]
  var prefixOperators: [OperatorName : Operator] = [:]
  var postfixOperators: [OperatorName : Operator] = [:]

  public init() { }

  /// Initialize the operator precedence instance with a given set of
  /// operators and precedence groups.
  public init(
    precedenceGroups: [PrecedenceGroup],
    operators: [Operator],
    errorHandler: OperatorPrecedenceErrorHandler = { throw $0 }
  ) rethrows {
    for group in precedenceGroups {
      try record(group, errorHandler: errorHandler)
    }
    for op in operators {
      try record(op, errorHandler: errorHandler)
    }
  }

  /// Record the operator in the given operator array.
  private func record(
    _ op: Operator,
    in table: inout [OperatorName : Operator],
    errorHandler: OperatorPrecedenceErrorHandler = { throw $0 }
  ) rethrows {
    if let existing = table[op.name] {
      try errorHandler(.operatorAlreadyExists(existing: existing, new: op))
    } else {
      table[op.name] = op
    }
  }

  /// Record the operator.
  mutating func record(
    _ op: Operator,
    errorHandler: OperatorPrecedenceErrorHandler = { throw $0 }
  ) rethrows {
    switch op.kind {
    case .infix:
      return try record(op, in: &infixOperators, errorHandler: errorHandler)

    case .prefix:
      return try record(op, in: &prefixOperators, errorHandler: errorHandler)

    case .postfix:
      return try record(op, in: &postfixOperators, errorHandler: errorHandler)
    }
  }

  /// Record the precedence group.
  mutating func record(
    _ group: PrecedenceGroup,
    errorHandler: OperatorPrecedenceErrorHandler = { throw $0 }
  ) rethrows {
    try precedenceGraph.add(group, errorHandler: errorHandler)
  }
}

extension OperatorTable {
  /// Look for the precedence group corresponding to the given operator.
  func lookupOperatorPrecedenceGroupName(
    _ operatorName: OperatorName,
    referencedFrom syntax: Syntax?,
    errorHandler: OperatorPrecedenceErrorHandler = { throw $0 }
  ) rethrows -> PrecedenceGroupName? {
    guard let op = infixOperators[operatorName] else {
      try errorHandler(
        .missingOperator(operatorName, referencedFrom: syntax))
      return nil
    }

    return op.precedenceGroup
  }
}
