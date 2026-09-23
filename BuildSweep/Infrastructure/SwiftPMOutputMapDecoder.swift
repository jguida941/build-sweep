import Foundation

nonisolated enum SwiftPMOutputMapFailure: Error, Equatable, Sendable {
    case byteLimitExceeded
    case invalidFormat
    case unsupportedEntry
}

/// Decodes declared per-source UTF-8 metadata without validating or opening its paths.
nonisolated struct SwiftPMOutputMapDecoder: Sendable {
    let maximumByteCount: Int

    init(maximumByteCount: Int = 1_048_576) {
        self.maximumByteCount = max(0, maximumByteCount)
    }

    func decode(_ data: Data) -> Result<[SwiftPMObjectReference], SwiftPMOutputMapFailure> {
        guard data.count <= maximumByteCount else {
            return .failure(.byteLimitExceeded)
        }
        var parser = OutputMapParser(data)
        guard let entries = try? parser.parse() else {
            return .failure(.invalidFormat)
        }

        // The empty key describes whole-module outputs, not a source file.
        guard entries[""]?["object"] == nil else {
            return .failure(.unsupportedEntry)
        }

        var references: [SwiftPMObjectReference] = []
        for sourcePath in entries.keys.sorted() where !sourcePath.isEmpty {
            guard let objectPath = entries[sourcePath]?["object"], !objectPath.isEmpty else {
                return .failure(.unsupportedEntry)
            }
            references.append(SwiftPMObjectReference(
                sourcePath: sourcePath,
                objectPath: objectPath
            ))
        }
        return .success(references)
    }
}

// Read only the supported two-level string map so duplicate names cannot disappear in decoding.
private nonisolated struct OutputMapParser {
    private let bytes: [UInt8]
    private var offset = 0
    private let stringDecoder = JSONDecoder()

    init(_ data: Data) {
        bytes = Array(data)
    }

    mutating func parse() throws -> [String: [String: String]] {
        let entries = try readObject { parser in
            try parser.readObject { try $0.readString() }
        }
        skipWhitespace()
        guard offset == bytes.count else {
            throw SwiftPMOutputMapFailure.invalidFormat
        }
        return entries
    }

    private mutating func readObject<Value>(
        readValue: (inout OutputMapParser) throws -> Value
    ) throws -> [String: Value] {
        try require(UInt8(ascii: "{"))
        var entries: [String: Value] = [:]
        if consume(UInt8(ascii: "}")) {
            return entries
        }
        while true {
            let key = try readString()
            guard entries[key] == nil else {
                throw SwiftPMOutputMapFailure.invalidFormat
            }
            try require(UInt8(ascii: ":"))
            entries[key] = try readValue(&self)
            if consume(UInt8(ascii: "}")) {
                return entries
            }
            try require(UInt8(ascii: ","))
        }
    }

    private mutating func readString() throws -> String {
        skipWhitespace()
        let start = offset
        try require(UInt8(ascii: "\""))
        while offset < bytes.count {
            let byte = bytes[offset]
            offset += 1
            if byte == UInt8(ascii: "\"") {
                // Foundation validates and decodes escapes before names are compared.
                return try stringDecoder.decode(String.self, from: Data(bytes[start..<offset]))
            }
            if byte == UInt8(ascii: "\\") {
                guard offset < bytes.count else {
                    throw SwiftPMOutputMapFailure.invalidFormat
                }
                offset += 1
            }
        }
        throw SwiftPMOutputMapFailure.invalidFormat
    }

    private mutating func require(_ byte: UInt8) throws {
        guard consume(byte) else {
            throw SwiftPMOutputMapFailure.invalidFormat
        }
    }

    private mutating func consume(_ byte: UInt8) -> Bool {
        skipWhitespace()
        guard offset < bytes.count, bytes[offset] == byte else {
            return false
        }
        offset += 1
        return true
    }

    private mutating func skipWhitespace() {
        while offset < bytes.count {
            switch bytes[offset] {
            case 0x20, 0x09, 0x0A, 0x0D:
                offset += 1
            default:
                return
            }
        }
    }
}
