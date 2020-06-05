import DataPackage

extension Log {
    func print() {
        for item in self.items {
            let prefix: String
            switch item.level {
            case .warning:
                prefix = "Warning"
            case .error:
                prefix = "Error"
            }

            Swift.print(prefix + ": " + item.description)
        }
    }
}
