import Foundation

/// Main client for interacting with the Anthropic API
public class Anthropic {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1"
    private let version = "2023-06-01"
    
    public var messages: Messages? = nil
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.messages = Messages(client: self)
    }
    
    /// Messages API interface
    public class Messages {
        private let client: Anthropic
        
        init(client: Anthropic) {
            self.client = client
        }
        
        /// Create a new message
        public func create(
            model: String,
            messages: [Message],
            system: String? = nil,
            metadata: MessageMetadata? = nil,
            stream: Bool = false
        ) async throws -> MessageResponse {
            var request = URLRequest(url: URL(string: "\(client.baseURL)/messages")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue(client.apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue(client.version, forHTTPHeaderField: "anthropic-version")
            
            let body = CreateMessageRequest(
                model: model,
                messages: messages,
                system: system,
                metadata: metadata,
                stream: stream
            )
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnthropicError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw try decodeError(from: data, statusCode: httpResponse.statusCode)
            }
            
            return try JSONDecoder().decode(MessageResponse.self, from: data)
        }
        
        /// Stream a message response
        public func stream(
            model: String,
            messages: [Message],
            system: String? = nil,
            metadata: MessageMetadata? = nil
        ) -> AsyncThrowingStream<MessageStreamEvent, Error> {
            AsyncThrowingStream { continuation in
                Task {
                    do {
                        var request = URLRequest(url: URL(string: "\(client.baseURL)/messages")!)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "content-type")
                        request.setValue(client.apiKey, forHTTPHeaderField: "x-api-key")
                        request.setValue(client.version, forHTTPHeaderField: "anthropic-version")
                        
                        let body = CreateMessageRequest(
                            model: model,
                            messages: messages,
                            system: system,
                            metadata: metadata,
                            stream: true
                        )
                        request.httpBody = try JSONEncoder().encode(body)
                        
                        let (result, response) = try await URLSession.shared.bytes(for: request)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw AnthropicError.invalidResponse
                        }
                        
                        if httpResponse.statusCode != 200 {
                            let data = try await result.reduce(into: Data()) { data, byte in
                                data.append(byte)
                            }
                            throw try decodeError(from: data, statusCode: httpResponse.statusCode)
                        }
                        
                        for try await line in result.lines {
                            guard line.hasPrefix("data: ") else { continue }
                            let json = String(line.dropFirst(6))
                            if let data = json.data(using: .utf8),
                               let event = try? JSONDecoder().decode(MessageStreamEvent.self, from: data) {
                                continuation.yield(event)
                            }
                        }
                        
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
}

// MARK: - Request/Response Models

public struct Message: Codable {
    public let role: String
    public let content: [[String: Any]]
    
    public init(role: String, content: [[String: Any]]) {
        self.role = role
        self.content = content
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(String.self, forKey: .role)
        
        // Handle content decoding
        if let contentArray = try? container.decode([[String: AnyCodable]].self, forKey: .content) {
            content = contentArray.map { dict in
                dict.mapValues { $0.value }
            }
        } else {
            content = []
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        
        // Convert content to AnyCodable for encoding
        let codableContent = content.map { dict in
            dict.mapValues { AnyCodable($0) }
        }
        try container.encode(codableContent, forKey: .content)
    }
    
    enum CodingKeys: String, CodingKey {
        case role
        case content
    }
}

// Helper type to encode/decode Any
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodable.init))
        default:
            try container.encodeNil()
        }
    }
}

struct CreateMessageRequest: Codable {
    let model: String
    let messages: [Message]
    let system: String?
    let max_tokens = 8192
    let metadata: MessageMetadata?
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case system
        case max_tokens = "max_tokens"
        case metadata
        case stream
    }
}

public struct MessageResponse: Codable {
    public let id: String
    public let type: String
    public let role: String
    public let content: [ContentBlock]
    public let model: String
    public let stopReason: String?
    public let stopSequence: String?
    public let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

public struct ContentBlock: Codable {
    public let type: String
    public let text: String
}

public struct Usage: Codable {
    public let inputTokens: Int
    public let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

public struct MessageMetadata: Codable {
    public let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
    
    public init(userId: String?) {
        self.userId = userId
    }
}

// MARK: - Streaming

public enum MessageStreamEvent: Codable {
    case messageStart(Message)
    case contentBlockStart(Int, ContentBlock)
    case contentBlockDelta(Int, ContentDelta)
    case contentBlockStop(Int)
    case messageDelta(MessageDelta)
    case messageStop
    case error(AnthropicError)
    
    enum CodingKeys: String, CodingKey {
        case type
        case message
        case index
        case contentBlock = "content_block"
        case delta
        case error
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .messageStart(let message):
            try container.encode("message_start", forKey: .type)
            try container.encode(message, forKey: .message)
        case .contentBlockStart(let index, let block):
            try container.encode("content_block_start", forKey: .type)
            try container.encode(index, forKey: .index)
            try container.encode(block, forKey: .contentBlock)
        case .contentBlockDelta(let index, let delta):
            try container.encode("content_block_delta", forKey: .type)
            try container.encode(index, forKey: .index)
            try container.encode(delta, forKey: .delta)
        case .contentBlockStop(let index):
            try container.encode("content_block_stop", forKey: .type)
            try container.encode(index, forKey: .index)
        case .messageDelta(let delta):
            try container.encode("message_delta", forKey: .type)
            try container.encode(delta, forKey: .delta)
        case .messageStop:
            try container.encode("message_stop", forKey: .type)
        case .error(let error):
            try container.encode("error", forKey: .type)
            try container.encode(error, forKey: .error)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "message_start":
            let message = try container.decode(Message.self, forKey: .message)
            self = .messageStart(message)
        case "content_block_start":
            let index = try container.decode(Int.self, forKey: .index)
            let block = try container.decode(ContentBlock.self, forKey: .contentBlock)
            self = .contentBlockStart(index, block)
        case "content_block_delta":
            let index = try container.decode(Int.self, forKey: .index)
            let delta = try container.decode(ContentDelta.self, forKey: .delta)
            self = .contentBlockDelta(index, delta)
        case "content_block_stop":
            let index = try container.decode(Int.self, forKey: .index)
            self = .contentBlockStop(index)
        case "message_delta":
            let delta = try container.decode(MessageDelta.self, forKey: .delta)
            self = .messageDelta(delta)
        case "message_stop":
            self = .messageStop
        case "error":
            let error = try container.decode(AnthropicError.self, forKey: .error)
            self = .error(error)
        default:
            throw AnthropicError.invalidResponse
        }
    }
}

public struct ContentDelta: Codable {
    public let type: String
    public let text: String
}

public struct MessageDelta: Codable {
    public let stopReason: String?
    public let stopSequence: String?
    
    enum CodingKeys: String, CodingKey {
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
    }
}

// MARK: - Error Handling

public enum AnthropicError: LocalizedError, Codable {
    case invalidResponse
    case apiError(type: String, message: String)
    case rateLimitExceeded
    case authenticationFailed
    case serverError
    
    enum CodingKeys: String, CodingKey {
        case type
        case errorType = "error_type"
        case message
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .invalidResponse:
            try container.encode("invalid_response", forKey: .type)
        case .apiError(let type, let message):
            try container.encode("api_error", forKey: .type)
            try container.encode(type, forKey: .errorType)
            try container.encode(message, forKey: .message)
        case .rateLimitExceeded:
            try container.encode("rate_limit_exceeded", forKey: .type)
        case .authenticationFailed:
            try container.encode("authentication_failed", forKey: .type)
        case .serverError:
            try container.encode("server_error", forKey: .type)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "invalid_response":
            self = .invalidResponse
        case "api_error":
            let errorType = try container.decode(String.self, forKey: .errorType)
            let message = try container.decode(String.self, forKey: .message)
            self = .apiError(type: errorType, message: message)
        case "rate_limit_exceeded":
            self = .rateLimitExceeded
        case "authentication_failed":
            self = .authenticationFailed
        case "server_error":
            self = .serverError
        default:
            self = .invalidResponse
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(_, let message):
            return message
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .authenticationFailed:
            return "Authentication failed"
        case .serverError:
            return "Server error occurred"
        }
    }
}

struct APIError: Codable {
    let type: String
    let error: ErrorDetails
    
    struct ErrorDetails: Codable {
        let type: String
        let message: String
    }
}

func decodeError(from data: Data, statusCode: Int) throws -> AnthropicError {
    if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        switch statusCode {
        case 401:
            return .authenticationFailed
        case 429:
            return .rateLimitExceeded
        case 500...599:
            return .serverError
        default:
            return .apiError(type: error.error.type, message: error.error.message)
        }
    }
    return .invalidResponse
} 
