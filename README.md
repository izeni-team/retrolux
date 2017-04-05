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
pod "Retrolux", "~> 0.4.0"
```

## Carthage

In your `Cartfile`:

```
github "izeni-team/retrolux" ~> 0.4.0
```

Then follow the instructions mentioned in [Carthage's documentation](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

# Examples

* [JSON](#json)
* [Multipart Form-Data](#multipart-form-data)
* [URL Encoded](#url-encoded)
* [Queries](#queries)
* [Custom Serializers](#custom-serializers)

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

let builder = RetroluxBuilder(baseURL: URL(string: "https://my.api.com/")!)
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

let builder = RetroluxBuilder(baseURL: URL(string: "https://my.api.com/")!)
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

let builder = RetroluxBuilder(baseURL: URL(string: "https://my.api.com/")!)
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
let builder = RetroluxBuilder(baseURL: URL(string: "https://my.api.com/")!)
let deleteUser = builder.makeRequest(
    method: .delete,
    endpoint: "users/{id}/",
    args: Path("id"),
    response: Void.self
)

deleteUser().enqueue { response in
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

let builder = RetroluxBuilder(baseURL: "https://my.api.com/")!)
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

let builder = RetroluxBuilder(baseURL: "https://my.api.com/")!)
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

let builder = RetroluxBuilder(baseURL: "https://my.api.com/")!)
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
let builder = RetroluxBuilder(baseURL: URL(string: "https://my.api.com/")!)

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
