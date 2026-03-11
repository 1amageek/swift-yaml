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
    case key                   // implicit/explicit key
    case value                 // :
    case flowSequenceStart     // [
    case flowSequenceEnd       // ]
    case flowMappingStart      // {
    case flowMappingEnd        // }
    case flowEntry             // ,
    case scalar(String, ScalarStyle)
    case documentStart         // ---
    case documentEnd           // ...
    case anchor(String)        // &name
    case alias(String)         // *name
    case tag(String)           // !tag, !!type, etc.
}
