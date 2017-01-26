# retrolux
The all in one networking solution for iOS.

Project Goal: Allow developers to describe their API instead of implementing code to consume it, like Square's Retrofit for Android.

Basic JSON example:

```swift
class SearchRequest: Reflection {
    var latitude: Float = 0
    var longitude: Float = 0
}

class SearchResponse: Reflection {
    var results: [SearchResult] = []
}

class SearchResult: Reflection {
    var title = ""
    var image: URL?
    var id = ""
}

let builder = RetroluxBuilder(baseURL: URL(string: "http://api.example.com/")!)
let request = builder.makeRequest(
    method: .post,
    endpoint: "some/endpoint/",
    args: (Query("distance"), Body<SearchRequest>()),
    response: Body<SearchResponse>()
    )

let searchRequest = SearchRequest()
searchRequest.latitude = -41
searchRequest.longitude = 123
request((Query("50"), Body(searchRequest))).enqueue { response in
    switch response.result {
    case .success(let searchResponse):
        let titles = searchResponse.results.map { $0.name }
        let ids = searchResponse.results.map { $0.id }
        let images = searchResponse.results.map { $0.url }
        populate(titles, ids, images)
    case .failure(let error):
        handle(error)
    }
}
```

---

And here's a basic multipart form data example:

```swift
class User: Reflection {
    var id = ""
    var first_name = ""
    var last_name = ""
    var image: URL?
    ...
}

let builder = RetroluxBuilder(baseURL: URL(string: "http://api.example.com/")!)
let request = builder.makeRequest(
    method: .post,
    endpoint: "api/media/{id}/upload/",
    args: (Path("id"), Part(name: "image", filename: "image.png", mimeType: "image/png")),
    response: Body<User>()
    )

let currentUserId = getCurrentUserId()
let imageData = UIImagePNGRepresentation(getUserImage())!

request((Path(currentUserId), Part(imageData))).enqueue { response in
    switch response.result {
    case .success(let user):
        update(with: user)
    case .failure(let error):
        handle(error)
    }
}
```
