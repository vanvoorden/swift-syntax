import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PropertyWrapperMacro {}

extension PropertyWrapperMacro: AccessorMacro, Macro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard let varDecl = declaration.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
    else {
      return []
    }
    
    return [
      """
      get {
        _\(raw: identifier.trimmedDescription).wrappedValue
      }
      """,
      """
      set {
        _\(raw: identifier.trimmedDescription).wrappedValue = newValue
      }
      """,
    ]
  }
}

extension PropertyWrapperMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let varDecl = declaration.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
          binding.accessorBlock == nil,
          let type = binding.typeAnnotation?.type
    else {
      return []
    }
    
    if let initializer = binding.initializer {
      return [
        """
        private var _\(raw: identifier.trimmedDescription) = PropertyWrapper<\(raw: type.trimmedDescription)>(storage: \(raw: initializer.value))
        """
      ]
    }
    
    return [
      """
      private var _\(raw: identifier.trimmedDescription): PropertyWrapper<\(raw: type.trimmedDescription)>
      """
    ]
  }
}
