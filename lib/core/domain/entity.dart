/// Marker base class for domain entities.
///
/// Every entity exposes a stable identifier used for equality between
/// representations of the same record across layers.
abstract class Entity {
  const Entity();

  /// Stable identifier. Implementations typically return a `String` UUID.
  Object get id;
}
