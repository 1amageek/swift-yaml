/// Scalar quoting style.
enum ScalarStyle: Sendable {
    case plain
    case singleQuoted
    case doubleQuoted
}

/// Tokens produced by the YAML scanner.
enum Token: Sendable {
    case streamStart
    case streamEnd
    case blockMappingStart
    case blockSequenceStart
    case blockEnd
    case blockEntry            // -
    case key                   // implicit key
    case value                 // :
    case flowSequenceStart     // [
    case flowSequenceEnd       // ]
    case flowMappingStart      // {
    case flowMappingEnd        // }
    case flowEntry             // ,
    case scalar(String, ScalarStyle)
}
