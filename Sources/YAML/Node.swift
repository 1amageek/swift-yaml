/// A YAML node representing a parsed document value.
public enum Node: Sendable, Hashable {
    case scalar(Scalar)
    case mapping(Mapping)
    case sequence(Sequence)
}
