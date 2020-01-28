//
//  BuilderDecoder.swift
//  TypeBuilder
//

/// Keep context of the current decodable part
struct Context<Type: Buildable> {
    private let builder: Builder<Type>
    private(set) var path: [CodingKey]

    init(builder: Builder<Type>) {
        self.builder = builder
        path = []
    }

    mutating func push(_ key: CodingKey) {
        path.append(key)
    }

    mutating func pop() {
        path.removeLast()
    }

    /// Check is builder have value for optional key
    func contains() throws -> Bool {
        return try builder.contains(path)
    }

    // Check is optional keyPath is nil
    func isNil() throws -> Bool {
        return try builder.isNil(path)
    }

    /// Return value of current path
    func value<Z>() throws -> Z {
        return try builder.value(for: path)
    }
}

class TypeDecoder<Root: Buildable> {
    class KeyedContainer<Key: CodingKey, Type: Buildable> {
        private let decoder: TypeDecoder<Type>
        private(set) var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any] = [:]
        let allKeys: [Key] = []

        init(root decoder: TypeDecoder<Type>) {
            self.decoder = decoder
            codingPath = decoder.codingPath
        }
    }

    class UnkeyedContainer {
        var codingPath: [CodingKey]
        var count: Int?
        var isAtEnd: Bool = false
        var currentIndex: Int = 0

        init(codingPath: [CodingKey]) {
            self.codingPath = codingPath
        }
    }

    var context: Context<Root>
    var codingPath: [CodingKey] {
        context.path
    }
    let userInfo: [CodingUserInfoKey : Any] = [:]

    convenience public init(builder: Builder<Root>) {
        self.init(context: Context(builder: builder))
    }

    init(context: Context<Root>) {
        self.context = context
    }
}

extension TypeDecoder: Decoder {
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = KeyedContainer<Key, Root>(root: self)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        // TODO add support of unkeyed containers
        fatalError()
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

extension TypeDecoder.KeyedContainer: KeyedDecodingContainerProtocol {

    func contains(_ key: Key) -> Bool {
        decoder.context.push(key)
        defer { decoder.context.pop() }

        guard let result = try? decoder.context.contains() else {
            // If we can't found a key path, we don't have this value eather
            return false
        }
        return result
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        decoder.context.push(key)
        defer { decoder.context.pop() }

        guard let result = try? decoder.context.isNil() else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: codingPath,
                                                                  debugDescription: "No value associated with key \(key)"))
        }
        return result
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        decoder.context.push(key)
        defer { self.decoder.context.pop() }

        let value = try T(from: decoder)
        return value
    }

    // TODO write it up
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError()
    }

    func superDecoder() throws -> Decoder {
        fatalError()
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError()
    }

}

extension TypeDecoder: SingleValueDecodingContainer {

    func decodeNil() -> Bool {
        guard let result = try? context.isNil() else {
            return false
        }
        return result
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try context.value()
    }
}
