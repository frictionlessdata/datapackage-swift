import TableSchema
import Foundation

extension Field: Serializable, Verifiable {

    public enum Key: String {
    case name
    case title
    case description
    case type
    case format
    case rdfType
    case constraints
    }

    public enum ConstraintKey: String {
    case `required`
    case unique
    // case minLength
    // case maxLength
    // case minimum
    // case maximum
    // case pattern
    // case `enum`
    }

    public enum AdditionalKey: String {
    case trueValues
    case falseValues
    case bareNumber
    }

    // MARK: - Setup & Teardown

    public convenience init?(descriptor: [String: Any], log: inout Log) {
        guard let name = descriptor[Key.name.rawValue] as? String else {
            log.append(keyPath: [Key.name.rawValue], level: .error, entry: .missing)
            return nil
        }

        self.init(name)

        if let title = descriptor[Key.title.rawValue] as? String {
            self.title = title
        }

        if let description = descriptor[Key.description.rawValue] as? String {
            self.description = description
        }

        if let rdfTypePath = descriptor[Key.rdfType.rawValue] as? String {
            if let url = URL(string: rdfTypePath) {
                self.rdfType = url
            } else {
                log.append(keyPath: [Key.rdfType.rawValue], level: .warning, entry: .badInput(rdfTypePath))
            }
        }

        if let typeDescriptor = descriptor[Key.type.rawValue] as? String {
            if let type = FieldType(rawValue: typeDescriptor) {
                self.type = type
            } else {
                log.append(keyPath: [Key.type.rawValue], level: .error, entry: .unknownEnumeration(typeDescriptor))
            }
        }

        if let formatDescriptor = descriptor[Key.format.rawValue] as? String {
            if let format = Format(description: formatDescriptor) {
                self.format = format
            } else {
                log.append(keyPath: [Key.format.rawValue], level: .error, entry: .unknownEnumeration(formatDescriptor))
            }
        }

        // Constraints

        if let constraints = descriptor[Key.constraints.rawValue] as? [String: Any] {
            if let required = constraints[ConstraintKey.required.rawValue] as? Bool {
                self.constraints.required = required
            }

            if let unique = constraints[ConstraintKey.unique.rawValue] as? Bool {
                self.constraints.unique = unique
            }
        }

        // Additionals

        if let trueValues = descriptor[AdditionalKey.trueValues.rawValue] as? [String] {
            self.trueValues = trueValues
        }

        if let falseValues = descriptor[AdditionalKey.falseValues.rawValue] as? [String] {
            self.falseValues = falseValues
        }
    }

    // MARK: - Serializable

    func serialize() -> [String: Any] {
        var descriptor = [String: Any]()

        descriptor[Key.name.rawValue] = self.name
        descriptor[Key.title.rawValue] = self.title
        descriptor[Key.description.rawValue] = self.description
        descriptor[Key.rdfType.rawValue] = self.rdfType?.absoluteString
        descriptor[Key.type.rawValue] = self.type.rawValue

        if self.format != Format.default {
            descriptor[Key.format.rawValue] = self.format.description
        }

        var constraints = [String: Any]()
        if let required = self.constraints.required {
            constraints[ConstraintKey.required.rawValue] = required
        }
        if let unique = self.constraints.unique {
            constraints[ConstraintKey.unique.rawValue] = unique
        }
        if constraints.count > 0 {
            descriptor[Key.constraints.rawValue] = constraints
        }

        if self.type == .boolean {
            descriptor[AdditionalKey.trueValues.rawValue] = self.trueValues
            descriptor[AdditionalKey.falseValues.rawValue] = self.falseValues
        }

        return descriptor
    }

    // MARK: - Verifiable

    @discardableResult
    public func verify(log: inout Log) -> Bool {
        return true
    }

}

internal extension Array where Element == Field {

    // Compares referencingFields for uniqueness (case-sensitive and case-insensitive) and that referencingFields is contained within self
    func verify(by referencingFields: [Field], keyPath: [String], referencingKeyPath: [String], log: inout Log) -> (valid: Bool, unique: Bool) {
        var valid = true
        var unique = true

        let fieldsByName = self.groupByName
        let uniqueFieldsByName = self.uniqueByName
        var uniqueFields = Set<Field>()

        for referencingField in referencingFields {
            let name = referencingField.name
            if let fields = fieldsByName[name], let field = fields.first {
                let (inserted, _) = uniqueFields.insert(field)
                if !inserted {
                    // Foreign key field names are not unique
                    unique = false
                    log.append(keyPath: referencingKeyPath, level: .warning, entry: .conflicting(referencingKeyPath))
                }
            } else if let field = uniqueFieldsByName[name.lowercased()] {
                // Found a non-case sensitive corresponding key for foreign key
                log.append(keyPath: referencingKeyPath, level: .warning, entry: .conflicting(keyPath))

                let (inserted, _) = uniqueFields.insert(field)
                if !inserted {
                    // Foreign key field names are not unique
                    unique = false
                    log.append(keyPath: referencingKeyPath, level: .warning, entry: .conflicting(referencingKeyPath))
                }
            } else {
                // Missing corresponding field
                valid = false
                log.append(keyPath: referencingKeyPath, level: .error, entry: .badInput(name))
            }
        }

        return (valid, unique)
    }

}

internal extension Array where Element == String {

    func fields(by referencingFields: [Field], keyPath: [String], referencingKeyPath: [String], log: inout Log) -> [Field]? {
        var destinationFields = [Field]()
        let fieldsByName = referencingFields.groupByName
        let uniqueFieldsByName = referencingFields.uniqueByName

        for name in self {
            if let fields = fieldsByName[name], let field = fields.first {
                destinationFields.append(field)
            } else if let field = uniqueFieldsByName[name.lowercased()] {
                destinationFields.append(field)

                // Found a non-case sensitive corresponding field
                log.append(keyPath: keyPath, level: .warning, entry: .conflicting(referencingKeyPath))
            } else {
                // Corresponding field not found
                log.append(keyPath: keyPath, level: .error, entry: .conflicting(referencingKeyPath))

                return nil
            }
        }

        return destinationFields
    }

}
