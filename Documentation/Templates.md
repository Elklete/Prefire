# Templates

The v1 generator uses reviewed templates embedded in the source target. External
template paths and custom template execution are intentionally unsupported.
Template values that originate in preview names or configuration are escaped as
Swift string literals, and generated Swift is parsed before it is written.
