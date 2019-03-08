## ReactiveAPI Vision

### Goals
- Write APIs in a declarative style as much as possible, avoiding boilerplate and runtime reflection
- Stay reactive. This library depends on RxSwift because we want to use functional style as much as possible.
- Have thin layer on top of Apple's URLSession, without reinventing the wheel, staying as tiny as possible
- Separate session management and security concerns from the API implementations
- Enhance API testability and mocking
- Ease Automatic Code Generation of iOS REST APIs
- Being as much as similar as OkHttp / Retrofit stack on Android, to ease portability of thoughts, code and features between iOS and Android

### Scope
#### Things we will not support:
- Wrappers or adapters to/from other networking stacks on iOS (e.g. Alamofire)
- Anything which is not an open and standardized network protocol
- Objective-C compatibility. We moved away from that language and we prefer pure idiomatic Swift

You can, of course, implement anything you want on top of this library on your own and maintain it, but we are not going to include it if it's something specific to a single use-case. We prefer snippets and posts on StackOverflow for that specific scenarios.

### Technical Considerations
- **iOS version**:
We support iOS 10.3+ and we are going to move forward at the same pace as Apple does, closing support for iOS versions which falls behind, to keep maintenance effort at minimum.

- **Backports**:
We will not make new features available on older versions of this library. Only the latest will have all the features.
