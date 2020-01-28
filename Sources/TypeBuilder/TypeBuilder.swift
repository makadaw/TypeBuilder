//
//  TypeBuilder.swift
//  TypeBuilder
//

import Foundation

public typealias Buildable = Reflectable & Codable

@dynamicMemberLookup
public struct KeyPathLens<Root: Buildable, Type> {
    let builder: Builder<Root>
    let parent: KeyPath<Root, Type>

    public subscript<T>(dynamicMember keyPath: KeyPath<Type, T>) -> T? where T: ReflectionDecodable {
        get {
            return try? builder.value(for: parent.appending(path: keyPath))
        }
        set {
            let fullKeyPath = parent.appending(path: keyPath)
            do {
                try builder.updateValue(fullKeyPath, value: newValue)
            } catch (_) {
                print("Can't update value for key path \(fullKeyPath), but subscript can't throw")
            }
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Type, T?>) -> T? where T: ReflectionDecodable {
        get {
            return try? builder.value(for: parent.appending(path: keyPath))
        }
        set {
            let fullKeyPath = parent.appending(path: keyPath)
            do {
                try builder.updateValue(fullKeyPath, value: newValue)
            } catch (_) {
                print("Can't update value for key path \(fullKeyPath), but subscript can't throw")
            }
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Type, T>) -> KeyPathLens<Root, T> where T: Buildable {
        get {
            return builder.lens(for: parent.appending(path: keyPath))
        }
        set {
            // TODO
            // For now just ignore lenses assign
        }
    }
}

/// Type safe builder for type
@dynamicMemberLookup
public class Builder<Type: Buildable> {

    public enum Error<Value>: Swift.Error {
        case missingKey(String, type: Value)
        case missingKeyPath(KeyPath<Type, Value>)
        case nonReflectableKeyPath(KeyPath<Type, Value>)
        case missingPartialKeyPath(PartialKeyPath<Type>, Value)
        case invalidValueType(key: PartialKeyPath<Type>, excpect: Value, actualValue: Any?)
    }

    private var storage = [PartialKeyPath<Type>: Any?]()
    private var reflectableKeyPaths = [String: PartialKeyPath<Type>]()

    /// MARK: Value access
    func updateValue<T: ReflectionDecodable>(_ keyPath: KeyPath<Type, T>, value: T?) throws {
        guard let property = try? Type.reflectProperty(forKey: keyPath) else {
            throw Error.nonReflectableKeyPath(keyPath)
        }
        storage.updateValue(value, forKey: keyPath)
        reflectableKeyPaths[property.stringKeyPath] = keyPath
    }

    func value<T>(for keyPath: KeyPath<Type, T>) throws -> T {
        guard let value = storage[keyPath] else {
            throw Error.missingKeyPath(keyPath)
        }
        guard let typed = value as? T else {
            throw Error.invalidValueType(key: keyPath, excpect: T.self, actualValue: value)
        }
        return typed
    }

    /// MARK: Subscripts
    // TODO Combine with Lens subscripts
    public subscript<T>(dynamicMember keyPath: KeyPath<Type, T>) -> T? where T: ReflectionDecodable {
        get {
            return try? value(for: keyPath)
        }
        set {
            do {
                try updateValue(keyPath, value: newValue)
            } catch (_) {
                print("Can't update value for key path \(keyPath), but subscript can't throw")
            }
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Type, T?>) -> T? where T: ReflectionDecodable {
        get {
            return try? value(for: keyPath)
        }
        set {
            do {
                try updateValue(keyPath, value: newValue)
            } catch (_) {
                print("Can't update value for key path \(keyPath), but subscript can't throw")
            }
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Type, T>) -> KeyPathLens<Type, T> {
        get {
            return lens(for: keyPath)
        }
        set {
            // TODO
            // For now just ignore lenses assign
        }
    }

    /// MARK: Lenses
    func lens<T>(for keyPath: KeyPath<Type, T>) -> KeyPathLens<Type, T> {
        return KeyPathLens<Type, T>(builder: self, parent: keyPath)
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
        switch storage[keyPath] ?? .none {
        case .none:
            return true
        case .some(let value):
            // TODO check is optional is nil
            return value == nil
        }
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
        guard let value = storage[keyPath] else {
            throw Error.missingPartialKeyPath(keyPath, T.self)
        }
        guard let typed = value as? T else {
            throw Error.invalidValueType(key: keyPath, excpect: T.self, actualValue: value)
        }
        return typed
    }
}

public extension Builder {
    func build() throws -> Type {
        let decoder = TypeDecoder<Type>(builder: self)
        return try Type(from: decoder)
    }
}

extension ReflectedProperty {
    var stringKeyPath: String {
        return path.joined(separator: ".")
    }
}
