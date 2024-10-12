//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

protocol FunctionScopeSyntax: DeclSyntaxProtocol, WithGenericParametersScopeSyntax {
  var signature: FunctionSignatureSyntax { get }
}

extension FunctionScopeSyntax {
  /// Function parameters introduced by this function's signature.
  @_spi(Experimental) public var introducedNames: [LookupName] {
    signature.parameterClause.parameters.flatMap { parameter in
      LookupName.getNames(from: parameter)
    } + (parentScope?.is(MemberBlockSyntax.self) ?? false ? [.implicit(.self(self))] : [])
  }

  /// Lookup results from this function scope.
  /// Routes to generic parameter clause scope if exists.
  @_spi(Experimental) public func lookup(
    _ identifier: Identifier?,
    at lookUpPosition: AbsolutePosition,
    with config: LookupConfig
  ) -> [LookupResult] {
    var thisScopeResults: [LookupResult] = []

    if !signature.range.contains(lookUpPosition) {
      thisScopeResults = defaultLookupImplementation(
        identifier,
        at: position,
        with: config,
        propagateToParent: false
      )
    }

    return thisScopeResults
      + lookupThroughGenericParameterScope(
        identifier,
        at: lookUpPosition,
        with: config
      )
  }
}