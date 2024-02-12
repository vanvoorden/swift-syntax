import MacroExamplesImplementation
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class PropertyWrapperTests: XCTestCase {
  private let macros = ["PropertyWrapper": PropertyWrapperMacro.self]
  
  func testMacro() {
    assertMacroExpansion(
      """
      @PropertyWrapper var x: Int
      """,
      expandedSource: """
        var x: Int {
          get {
            _x.wrappedValue
          }
          set {
            _x.wrappedValue = newValue
          }
        }
        
        private var _x: PropertyWrapper<Int>
        """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }
  
  func testMacroWithInitializer() {
    assertMacroExpansion(
      """
      @PropertyWrapper var x: Int = 1
      """,
      expandedSource: """
        var x: Int {
          get {
            _x.wrappedValue
          }
          set {
            _x.wrappedValue = newValue
          }
        }
        
        private var _x = PropertyWrapper<Int>(storage: 1)
        """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }
}
