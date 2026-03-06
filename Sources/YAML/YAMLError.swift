/// Errors produced during YAML scanning or parsing.
public enum YAMLError: Error, Sendable, CustomStringConvertible {
    case scanner(message: String, mark: Mark)
    case parser(message: String, mark: Mark)
    case unexpectedEndOfInput(mark: Mark)

    public var description: String {
        switch self {
        case .scanner(let message, let mark):
            return "\(mark): scanner error: \(message)"
        case .parser(let message, let mark):
            return "\(mark): parser error: \(message)"
        case .unexpectedEndOfInput(let mark):
            return "\(mark): unexpected end of input"
        }
    }
}
