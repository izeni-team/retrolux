# Retrolux

Retrolux is a Swift alternative to [Square's Retrofit](https://github.com/square/retrofit) for Android. *It is currently in the early stages of development.*

Development is currently taking place on the `feature/refactor` branch.

Goals:
- Feature parity with Retrofit.
- Safe, simple, and familiar API.
- Declare endpoints without having to implement them.
- Ability to serialize HTTP response data straight into classes, and vice versa.
- Support XML, JSON, Protobufs, and other custom data formats.
- Lots of convenience in the form of extensions (to come later in project).
- Modular architecture to allow changing behavior easily.
- Test-driven with CI.

Current State: ~50% towards usable pre-alpha.
- JSON serializer is finished.
- Serialize HTTP response data to/from classes.
- Support XML, JSON, Protobufs, and other custom data formats.
- Some tests, no CI (yet).

Design:
- The design is largely inspired by Retrofit, but takes adaptations where the differences between Swift and Java prevent imitation. For example, when creating endpoints in Retrofit, you can simply declare an interface and then have Retrofit implement it for you at runtime. Problem is, Swift/Obj-C don't have APIs for reading interfaces, so instead Retrolux will take all customization parameters in the form of arguments (not annotations). This makes it challenging to create an API that is both flexible _and_ concise, but I'm confident I can nail it.
- The reflection provided by Retrolux is more flexible than any other solution out there (that I'm aware of, at least). And it does all of this while maintaining type-safety.
- The class reflection in Retrolux was largely inspired by the implementation in [RealmSwift](https://github.com/realm/realm-cocoa), but offers fewer limitations. For example, with Retrolux, having a property of type `Dictionary<String, Array<NSDate>>` will be serializable in Retrolux, but not Realm.
- The class reflection in Retrolux is also more flexible than [EVReflection](https://github.com/evermeer/EVReflection) because it supports properties of type `Array<SomeOtherSerializable>`, as well as the nested types like `Array<Dictionary<String, PersonObject>>`.
- Unlike RealmSwift and EVReflection, Retrolux's class reflection doesn't enforce you to subclass a specific class. This is because Retrolux's reflection methods are implemented as protocol extensions rather than a base class.
- The front-end interface is still being designed.
