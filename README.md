Retrolux is an all in one networking framework. It is intended to become the equivalent of [Square's Retrofit for Android](http://square.github.io/retrofit/).

**This framework is still in early development.**

# Why?

There are many good networking libraries out there already for iOS. [Alamofire](https://github.com/Alamofire/Alamofire), [AFNetworking](https://github.com/AFNetworking/AFNetworking), and [Moya](https://github.com/Moya/Moya), etc. are all great libraries.

What makes this framework unique is that each endpoint can be consicely described. No subclassing, protocol implementations, functions to implement, or extra modules to download. It comes with JSON, Multipart, and URL Encoding support out of the box. In short, it aims to optimize, as much as possible, the end-to-end process of network API consumption.

The purpose of this framework is not just to abstract away networking details, but also to provide a Retrofit-like workflow, where endpoints can be described--not implemented.

# Installation

## Cocoapods

In your `Podfile`:

```
pod "Retrolux"
```

## Carthage

In your `Cartfile`:

```
github "izeni-team/retrolux"
```

Then follow the instructions mentioned in [Carthage's documentation](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

# Examples

* [JSON](#json)
* [Multipart Form-Data](#multipart-form-data)
* [URL Encoded](#url-encoded)
* [Queries](#queries)
* [Custom Serializers](#custom-serializers)
* [Testing](#testing)
* [Changing Base URL](#changing-base-url)
* [Logging](#logging)
* [Reflection Customizations](#reflection-customizations)

# JSON

JSON support for Retrolux is provided by the [ReflectionJSONSerializer](ReflectionJSONSerializer) class.

For more information on reflection, refer to [Reflectable](Reflectable).

---

To get a list of items:

```swift
class Person: Reflection {
    var name = ""
    var age = 0
}

let builder = Builder(base: URL(string: "https://my.api.com/")!)
let getUsers = builder.makeRequest(
    method: .get,
    endpoint: "users/",
    args: Void, // Or (), because Void == ()
    response: [Person].self
)
getUsers().enqueue { response in
    switch response.interpreted { // What .interpreted means can be customized by overriding RetroluxBuilder's interpret function
    case .success(let users):
        print("Got \(users.count) users!")
    case .failure(let error):
        print("Failed to get users: \(error)")
    }
}
```

---

To post an item:

```swift
class Person: Reflection {
    var name = ""
    var age = 0
}

let builder = Builder(base: URL(string: "https://my.api.com/")!)
let createUser = builder.makeRequest(
    method: .post,
    endpoint: "users/",
    args: Person(),
    response: Person.self
)

let newUser = Person()
newUser.name = "Bob"
newUser.age = 3
createUser(newUser).enqueue { response in
    print("User created successfully? \(response.isSuccessful)")
    if let echo = response.body {
        print("Response: \(echo)")
    }
}
```

---

To patch an item:

```swift
class Person: Reflection {
    var id = ""
    var name = ""
    var age = 0
}

let builder = Builder(base: URL(string: "https://my.api.com/")!)
let patchUser = builder.makeRequest(
    method: .patch,
    endpoint: "users/{id}/",
    args: (Person(), Path("id")),
    response: Person.self
)

let existingUser = getExistingUserFromSomewhere()
existingUser.name = "Bob"
existingUser.age = 3
patchUser((newUser, Path(existingUser.id)).enqueue { response in
    print("User updated successfully? \(response.isSuccessful)")
    if let echo = response.body {
        print("Response: \(echo)")
    }
}
```

---

To delete an item:

```swift
let builder = Builder(base: URL(string: "https://my.api.com/")!)
let deleteUser = builder.makeRequest(
    method: .delete,
    endpoint: "users/{id}/",
    args: Path("id"),
    response: Void.self
)

deleteUser(Path(someUser.id)).enqueue { response in
    print("User was deleted? \(response.isSuccessful)")
}
```

# Multipart Form-Data

Multipart support is provided via the [MultipartFormDataSerializer](MultipartFormDataSerializer) class.

Multipart data can be sent by sending either [Field](Field) or [Part](Part) objects to the builder.

---

Simple sign-in:

```swift
class LoginResponse: Reflection {
    var token = ""
    var user_id = ""
}

let builder = Builder(base: "https://my.api.com/")!)
let login = builder.makeRequest(
    method: .post,
    endpoint: "login/",
    args: (Field("username"), Field("password")),
    response: LoginResponse.self
)
login((Field("bobby"), Field("abc123")).enqueue { response in
    switch response.interpreted {
    case .success(let login):
        print("Login successful! Token: \(login.token), user: \(login.user_id)")
    case .failure(let error):
        print("Failed to login: \(error)")
    }
}
```

---

Image upload:

```swift
class User: Reflection {
    var id = ""
    var name = ""
    var image_url: URL?
}

let builder = Builder(base: "https://my.api.com/")!)
let uploadImage = builder.makeRequest(
    method: .post,
    endpoint: "media_upload/{user_id}/",
    args: (Path("user_id"), Part(name: "image", filename: "image.png", mimeType: "image/png")),
    response: User.self
)

let image: UIImage = getImageFromCamera()
let imageData = UIImagePNGRepresentation(image)!
uploadImage((Path(someUser.id), Part(imageData)).enqueue { response in
    print("image URL is: \(response.body?.image_url)")
}
```

# URL Encoded

URL encoded bodies are provided by the [URLEncodedSerializer](URLEncodedSerializer) class.

Both [URLEncodedSerializer](URLEncodedSerializer) and [MultipartFormDataSerializer](MultipartFormDataSerializer) use [Field](Field) objects. By default, the multipart serializer will have higher priority. Thus, in order to use URL encoding, you need to manually specify the serializer that you would prefer by adding `type: .urlEncoded` to the `makeRequest` function, like below:

```swift
let login = builder.makeRequest(
    type: .urlEncoded, // This is required else the request will be sent as multipart form-data instead!
    method: .post,
    endpoint: "login/",
    args: (Field("username"), Field("password")),
    response: LoginResponse.self
)
```

---

Basic login example:

```swift
class LoginResponse: Reflection {
    var id = ""
    var token = ""
}

let builder = Builder(base: "https://my.api.com/")!)
let login = builder.makeRequest(
    type: .urlEncoded,
    method: .post,
    endpoint: "login",
    args: (Field("username"), Field("password")),
    response: LoginResponse.self
)
login((Field("bobby"), Field("abc123")).enqueue { response in
    switch response.interpreted {
    case .success(let login):
        print("id: \(login.id), token: \(login.token)")
    case .failure(let error):
        print("Login failed: \(error)")
    }
}
```

---

# Queries

Support for queries is provided by the [Query](../blob/master/Retrolux/Query.swift) object.

```swift
let find = builder.makeRequest(
    method: .get,
    endpoint: "users/",
    args: (Query("distance"), Query("age_gt")),
    response: [User].self
)
find((Query("50"), Query("20")).enqueue { response in
    ...
}
```

# Custom Serializers

Most of Retrolux's functionality is in the form of a plugin. Since all the other built-in serializers are merely plugins, it is easy to add new serializers.

For example, let's say you want to send/receive JSON using [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON):

```swift
import Foundation
import SwiftyJSON
import Retrolux

enum SwiftyJSONSerializerError: Error {
    case invalidJSON
}

class SwiftyJSONSerializer: InboundSerializer, OutboundSerializer {
    func supports(inboundType: Any.Type) -> Bool {
        return inboundType is JSON.Type
    }
    
    func supports(outboundType: Any.Type) -> Bool {
        return outboundType is JSON.Type
    }
    
    func validate(outbound: [BuilderArg]) -> Bool {
        return outbound.count == 1 && outbound.first!.type is JSON.Type
    }
    
    func apply(arguments: [BuilderArg], to request: inout URLRequest) throws {
        let json = arguments.first!.starting as! JSON
        request.httpBody = try json.rawData()
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T {
        let result = JSON(data: clientResponse.data ?? Data())
        if result.object is NSNull {
            throw SwiftyJSONSerializerError.invalidJSON
        }
        return result as! T
    }
}
```

And once you've created the serializer, you can send/receive using SwiftyJSON:

```swift
let builder = Builder(base: URL(string: "https://my.api.com/")!)

// This is how you tell Retrolux to use your serializer.
builder.serializers.append(SwiftyJSONSerializer())

let login = builder.makeRequest(
    method: .post,
    endpoint: "login/",
    args: JSON([:]),
    response: JSON.self
)

login(JSON(["username": "bobby", "password": "abc123"])).enqueue { response in
    switch response.interpreted {
    case .success(let json):
        let id = json["id"].stringValue
        let token = json["token"].stringValue
        print("Got id \(id) and token \(token)")
    case .failure(let error):
        print("Request failed: \(error)")
    }
}
```

# Testing

Retrolux makes unit testing easier with the concept of "dry mode." When [Builder](Builder) is run in dry mode by using the builder returned by `Builder.dry()`, then all requests skip the HTTP client and fake responses are used instead. If no fake response is provided in the endpoint, then an empty response is returned instead.

To specify what data you'd like to use in the fake response, do so like the following:

```swift
class LoginArgs: Reflection {
    var username = ""
    var password = ""
}

class LoginResponse: Reflection {
    var id = ""
    var token = ""
}

let builder = Builder.dry()
let login = builder.makeRequest(
    method: .post,
    endpoint: "login/",
    args: LoginArgs(),
    response: LoginResponse.self,
    testProvider: { (creation, starting, request) in
        ClientResponse(
            url: request.url!,
            data: "{\"id\":\"qs492s37\",\"token\":\"0s98q3wj5s5\",\"username\":\"\(starting.username)\"}".data(using: .utf8)!,
            status: 200
        )
    }
)

let args = LoginArgs()
login.username = "bobby"
login.password = "impenetrable"
let response = login(args).perform()
XCTAssert(response.isSuccessful)
XCTAssert(response.body?.id == "qs492s37")
XCTAssert(response.body?.token == "0s98q3wj5s5")
XCTAssert(response.body?.username == args.username)
```

# Changing Base URL

Requests capture the base URL when calling `.enqueue(...)` or `.perform()`.

For example:

```swift
let builder = Builder(base: URL(string: "https://www.google.com/")!)
let first = builder.makeRequest(
    method: .get,
    endpoint: "something",
    args: (),
    Response: Void.self
)

let call = first()
call.enqueue { response in
    // response.request.url == "https://www.google.com/something"
}

builder.base = URL(string: "https://www.something.else/")!
call.enqueue { response in
    // response.request.url == "https://www.something.else/something"
}
```

# Logging

Debug print statements are enabled by default. To customize logging, subclass Builder and override the `log` functions like so:

```swift
class MyBuilder: Builder {
    open override func log(request: URLRequest) {
        // To silence logging, do nothing here.
    }
    
    open override func log<T>(response: Response<T>) {
        // To silence logging, do nothing here.
    }
}
```

# Reflection Customizations

The reflection API supports customizing behavior by implementing the `static func config(_:PropertyConfig)` function, like so:

```swift
class MyDateTransformer: NestedTransformer {
    enum DateTransformationError: Error {
        case invalidDateFormat(got: String, expected: String)
    }
    
    typealias TypeOfData = String
    typealias TypeOfProperty = Date
    
    let formatter = { () -> DateFormatter in
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    func setter(_ dataValue: String, type: Any.Type) -> Date {
        guard let date = formatter.date(from: value) else {
            throw DateTransformationError.invalidDateFormat(
                got: value,
                expected: formatter.dateFormat
            )
        }
        return date
    }
    
    func getter(_ propertyValue: TypeOfProperty) -> String {
        return formatter.string(from: value)
    }
}

class Person: Reflection {
    var desc = "DEFAULT_VALUE"
    var notSupported: Int?
    var date = Date()
    
    override class func config(_ c: PropertyConfig) {
        c["desc"] = [
            .serializedName("description"), // Will look for the "description" key in JSON
            .nullable // If the value is null, don't raise a "null values not supported" error
        ]
        
        // 'Int?' is not a supported type, so this will tell Retrolux to ignore it instead of raising an error
        c["notSupported"] = [.ignored]
        
        // Alternatively, you can do Reflector.shared.globalTransformers.append(MyDateTransformer())
        c["date"] = [.transformed(MyDateTransformer())]
    }
}

let reflector = Reflector()
let person = try reflector.convert(
    fromDictionary: [
        "description": NSNull(),
        "date": "2017-04-17T12:02:04.142Z"
    ],
    to: Person.self
) as! Person
```
