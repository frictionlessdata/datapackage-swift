public protocol Validatable {
    // Factory method
    init?(descriptor: [String: Any], log: inout Log)
}
