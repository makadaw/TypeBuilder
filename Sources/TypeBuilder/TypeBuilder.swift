//
//  TypeBuilder.swift
//  TypeBuilder
//

import Foundation

public typealias Buildable = Reflectable & Codable

@dynamicMemberLookup
public struct KeyPathLens<Root: Buildable, CurrentType> {
    let builder: Builder<Root>
    let parent: KeyPath<Root, CurrentType>

    /// MARK: Subscripts
    public subscript<T>(dynamicMember keyPath: KeyPath<CurrentType, T>) -> KeyPathLens<Root, T> {
        get {
            let finalKeyPath = parent.appending(path: keyPath)
            return builder.lens(for: finalKeyPath)
        }
        set {
            let finalKeyPath = parent.appending(path: keyPath)
            builder.setLens(newValue, for: finalKeyPath)
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<CurrentType, T>) -> T where T: ReflectionDecodable {
        get {
            do {
                return try value(for: keyPath)
            } catch {
                fatalError("Value for \(keyPath) is nil, subscript is not throwable \(error)")
            }
        }
        set {
            do {
                try updateValue(keyPath, value: newValue)
            } catch {
                fatalError("Can't update value for key path \(keyPath), but subscript can't throw")
            }
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<CurrentType, T?>) -> T? where T: ReflectionDecodable {
        get {
            do {
                return try value(for: keyPath)
            } catch {
                fatalError("Value for \(keyPath) is nil, subscript is not throwable \(error)")
            }
        }
        set {
            do {
                try updateValue(keyPath, value: newValue)
            } catch {
                fatalError("Can't update value for key path \(keyPath), but subscript can't throw")
            }
        }
    }

    /// MARK: Values
    func value<T>(for keyPath: KeyPath<CurrentType, T>) throws -> T {
        let finalKeyPath = parent.appending(path: keyPath)
        return try builder.value(for: finalKeyPath)
    }

    func value<T>(for keyPath: KeyPath<CurrentType, T?>) throws -> T? {
        let finalKeyPath = parent.appending(path: keyPath)
        return try builder.value(for: finalKeyPath)
    }

    func updateValue<T: ReflectionDecodable>(_ keyPath: KeyPath<CurrentType, T>, value: T) throws {
        let finalKeyPath = parent.appending(path: keyPath)
        try builder.updateValue(finalKeyPath, value: value)
    }

    func updateValue<T: ReflectionDecodable>(_ keyPath: KeyPath<CurrentType, T?>, value: T?) throws {
        let finalKeyPath = parent.appending(path: keyPath)
        try builder.updateValue(finalKeyPath, value: value)
    }
}

@dynamicMemberLookup
public class Builder<Root: Buildable> {

    public enum Error<Value>: Swift.Error {
        case missingKey(String, type: Value)
        case missingKeyPath(KeyPath<Root, Value>)
        case nonReflectableKeyPath(KeyPath<Root, Value>)
        case missingPartialKeyPath(PartialKeyPath<Root>, Value)
        case invalidValueType(key: PartialKeyPath<Root>, excpect: Value, actualValue: Any?)
        case valueIsNil(key: PartialKeyPath<Root>, excpect: Value)
    }

    enum Value<T> {
        case none
        case value(T)
    }

    private var storage = [PartialKeyPath<Root>: Value<Any>]()
    private var reflectableKeyPaths = [String: PartialKeyPath<Root>]()

    /// MARK: Subscripts
    public subscript<T>(dynamicMember keyPath: KeyPath<Root, T>) -> KeyPathLens<Root, T> {
        get {
            return lens(for: keyPath)
        }
        set {
            setLens(newValue, for: keyPath)
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Root, T>) -> T where T: ReflectionDecodable {
        get {
            do {
                return try value(for: keyPath)
            } catch {
                fatalError("Value for \(keyPath) is nil, subscript is not throwable \(error)")
            }
        }
        set {
            do {
                try updateValue(keyPath, value: newValue)
            } catch {
                fatalError("Can't update value for key path \(keyPath), but subscript can't throw")
            }
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Root, T?>) -> T? where T: ReflectionDecodable {
        get {
            do {
                return try value(for: keyPath)
            } catch {
                fatalError("Value for \(keyPath) is nil, subscript is not throwable \(error)")
            }
        }
        set {
            do {
                try updateValue(keyPath, value: newValue)
            } catch {
                fatalError("Can't update value for key path \(keyPath), but subscript can't throw")
            }
        }
    }

    /// MARK: Value storage
    public func value<T>(for keyPath: KeyPath<Root, T>) throws -> T {
        guard let wrapper = storage[keyPath] else {
            throw Error.missingKeyPath(keyPath)
        }
        switch wrapper {
        case .none:
            throw Error.valueIsNil(key: keyPath, excpect: T.self)
        case let .value(value):
            guard let typed = value as? T else {
                throw Error.invalidValueType(key: keyPath, excpect: T.self, actualValue: value)
            }
            return typed
       }
    }

    public func value<T>(for keyPath: KeyPath<Root, T?>) throws -> T? {
        guard let wrapper = storage[keyPath] else {
             throw Error.missingKeyPath(keyPath)
        }
        switch wrapper {
        case .none:
            return nil
        case let .value(value):
            guard let typed = value as? T else {
                throw Error.invalidValueType(key: keyPath, excpect: T.self, actualValue: value)
            }
            return typed
        }
    }

    public func updateValue<T: ReflectionDecodable>(_ keyPath: KeyPath<Root, T>, value: T) throws {
        try updateValue(keyPath, value: .value(value))
    }

    public func updateValue<T: ReflectionDecodable>(_ keyPath: KeyPath<Root, T?>, value: T?) throws {
        let setValue: Value<Any>
        if let value = value {
            setValue = .value(value)
        } else {
            setValue = .none
        }
        try updateValue(keyPath, value: setValue)
    }

    func updateValue<T: ReflectionDecodable>(_ keyPath: KeyPath<Root, T>, value: Value<Any>) throws {
        guard let property = try? Root.reflectProperty(forKey: keyPath) else {
            throw Error.nonReflectableKeyPath(keyPath)
        }
        storage[keyPath] = value
        reflectableKeyPaths[property.stringKeyPath] = keyPath
    }

    /// MARK: Lenses
    func lens<T>(for keyPath: KeyPath<Root, T>) -> KeyPathLens<Root, T> {
        return KeyPathLens<Root, T>(builder: self, parent: keyPath)
    }

    func setLens<T>(_ lens: KeyPathLens<Root, T>, for keyPath: KeyPath<Root, T>) {
        // TODO
        // For now just ignore lenses assign
    }
}

/// MARK: String accessors
extension Builder {
    func keyPath(codingKeys: [CodingKey]) -> String {
        return codingKeys.map({ $0.stringValue }).joined(separator: ".")
    }

    func isNil(_ path: [CodingKey]) throws -> Bool {
        let key = keyPath(codingKeys: path)
        guard let keyPath = reflectableKeyPaths[key] else {
            throw Error.missingKey(key, type: Any.Type.self)
        }
        guard let val = storage[keyPath],
            case .value = val else {
            return true
        }
        return false
    }

    func contains(_ path: [CodingKey]) throws -> Bool {
        let key = keyPath(codingKeys: path)
        guard let keyPath = reflectableKeyPaths[key] else {
            return false
        }
        return storage[keyPath] != nil
    }

    func value<T>(for codingPath: [CodingKey]) throws -> T {
        let key = keyPath(codingKeys: codingPath)
        guard let keyPath = reflectableKeyPaths[key] else {
            throw Error.missingKey(key, type: T.self)
        }
        guard let wrapper = storage[keyPath],
            case let .value(value) = wrapper else {
            throw Error.missingPartialKeyPath(keyPath, T.self)
        }
        guard let typed = value as? T else {
            throw Error.invalidValueType(key: keyPath, excpect: T.self, actualValue: value)
        }
        return typed
    }
}

public extension Builder {
    func build() throws -> Root {
        let decoder = TypeDecoder<Root>(builder: self)
        return try Root(from: decoder)
    }
}

extension ReflectedProperty {
    var stringKeyPath: String {
        return path.joined(separator: ".")
    }
}
