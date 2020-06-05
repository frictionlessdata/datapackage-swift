public protocol Verifiable {
    func verify(log: inout Log) -> Bool
}
