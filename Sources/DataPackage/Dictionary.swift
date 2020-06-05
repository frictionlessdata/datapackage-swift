internal extension Dictionary where Key == String, Value == Any {
    func castArray<T>(_ type: T.Type, forKey key: String) -> [T]? {
        if let values = self[key] as? [T] {
            return values
        } else if let value = self[key] as? T {
            return [value]
        }
        return nil
    }
}
