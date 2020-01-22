//
//  TypeBuilder.swift
//  TypeBuilder
//

import Foundation

extension ReflectedProperty {
    func toKeyPath() -> String {
        return path.joined(separator: ".")
    }
}

/// Type safe builder for type
public struct Builder<Type: Reflectable> {

    enum Value<T> {
        case some(T)
        case none

        func unbox() -> T? {
            switch self {
            case .some(let wrapped):
                return wrapped
            case .none:
                return nil
            }
        }
    }

    public enum Error<Value>: Swift.Error {
        case missingKey(String, type: Value)
        case missingKeyPath(KeyPath<Type, Value>)
        case missingPartialKeyPath(PartialKeyPath<Type>, Value)
        case invalidValueType(key: PartialKeyPath<Type>, excpect: Value, actualValue: Any?)
    }

    private var storage = [PartialKeyPath<Type>: Value<Any>]()
    private var reflectableKeyPaths = [String: PartialKeyPath<Type>]()

    func value<Z>(for keyPath: KeyPath<Type, Z>) throws -> Z {
        guard let value = storage[keyPath] else {
            throw Error.missingKeyPath(keyPath)
        }
        guard let typed = value.unbox() as? Z else {
            throw Error.invalidValueType(key: keyPath, excpect: Z.self, actualValue: value)
        }
        return typed
    }

    mutating func updateValue<T>(_ value: Value<Any>?, for keyPath: KeyPath<Type, T>) {
        // Store values only for reflected properties
        if let property = try? Type.reflectProperty(forKey: keyPath) {
            if let value = value {
                storage[keyPath] = value
            } else {
                storage[keyPath] = nil
            }
            reflectableKeyPaths[property.toKeyPath()] = keyPath
        }
    }

    public subscript<Z>(_ keyPath: KeyPath<Type, Z>) -> Z? {
        get {
            return try? value(for: keyPath)
        }
        set {
            var value: Value<Any>? = nil
            if let some = newValue {
                value = .some(some)
            }
            updateValue(value, for: keyPath)
        }
    }

    public subscript<Z>(_ keyPath: KeyPath<Type, Z?>) -> Z? {
        get {
            return try? value(for: keyPath)
        }
        set {
            var value: Value<Any> = .none
            if let some = newValue {
                value = .some(some)
            }
            updateValue(value, for: keyPath)
        }
    }

    private func unbox<T>(_ value: Value<Any>, of type: T, for keyPath: PartialKeyPath<Type>) throws -> T? {
        switch value {
        case .some(let wrapped):
            guard let typed = wrapped as? T else {
                throw Error.invalidValueType(key: keyPath, excpect: T.self, actualValue: wrapped)
            }
            return typed
        case .none:
            return nil as T?
        }
    }
}

/// MARK: Decoder methods
extension Builder {

    func keyPath(codingKeys: [CodingKey]) -> String {
        return codingKeys.map({ $0.stringValue }).joined(separator: ".")
    }

    func isNil(_ path: [CodingKey]) throws -> Bool {
        let key = keyPath(codingKeys: path)
        guard let keyPath = reflectableKeyPaths[key] else {
            throw Error.missingKey(key, type: Any.Type.self)
        }
        switch storage[keyPath] ?? .none {
        case .none:
            return true
        default:
            return false
        }
    }

    func contains(_ path: [CodingKey]) throws -> Bool {
        let key = keyPath(codingKeys: path)
        guard let keyPath = reflectableKeyPaths[key] else {
            throw Error.missingKey(key, type: Any.Type.self)
        }
        return storage[keyPath] != nil
    }

    func value<T>(for codingPath: [CodingKey]) throws -> T {
        let key = keyPath(codingKeys: codingPath)
        guard let keyPath = reflectableKeyPaths[key] else {
            throw Error.missingKey(key, type: T.self)
        }
        guard let value = storage[keyPath] else {
            throw Error.missingPartialKeyPath(keyPath, T.self)
        }
        guard let typed = value.unbox() as? T else {
            throw Error.invalidValueType(key: keyPath, excpect: T.self, actualValue: value)
        }
        return typed
    }
}

public extension Builder where Type: Codable {
    func build() throws -> Type {
        let decoder = TypeDecoder<Type>(builder: self)
        return try Type(from: decoder)
    }
}

