////
////  Builder.swift
////  Retrolux
////
////  Created by Christopher Bryan Henderson on 8/8/17.
////  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
////
//
//import Foundation
//
//// How to ignore a key:
// //struct MyThing: Codable {
// //    enum CodingKeys: CodingKey {
// //        case name = "something_else"
// //    }
// //
// //    let id: Int? = nil
// //    let name: String
// //}
//
//struct Yay: Codable {
//    enum CodingKeys: CodingKey {
//        case id
//    }
//
//    let id: String
//    let whatever = ""
//}
//
//struct MyThing: Codable {
//    enum CodingKeys: CodingKey {
//        case name
//        case friends
//    }
//
//    let id: Int? = nil
//    let name: String
//    let friends: [Yay]
//}
//
//func t() {
////    let decoder = JSONDecoder()
////    let t = try! decoder.decode(MyThing.self, from: """
////    {
////        "id": null,
////        "friends": [{
////            "id": "wrongo"
////        }],
////        "name": "Bob"
////    }
////    """.data(using: .utf8)!)
////
////    Mirror(reflecting: t).children
////
////    let t2 = try! decoder.decode(MyThing.self, from: """
////    {
////        "id": 2
////    }
////    """.data(using: .utf8)!)
//
//}
//
////protocol Request {
////
////    var method: String {get}
////    var endpoint: String {get}
////
////    associatedtype Args
////    var args: Args {get}
////    associatedtype Response
////}
////
////extension Request {
////
////    var method: String { return "get"}
////
////    var args: () {
////        return ()
////    }
////
////    var creation:Int {
////        return 3
////    }
////}
//
////struct Concrete: Request {
////    var endpoint: String = "test.com"
////    typealias Response = String
////}
//
//enum Method {
//    case get(String)
//}
//
////struct Path<Number> {
////
////    init(_ a: Number) {}
////
////}
////
//
////struct M {
////
////
////
////    static func get<A>(_ endpoint: String, path: A = ()) -> Path2<A, Q> {
////
////        fatalError()
////
////    }
////}
////
////func make<T: M>(_ method: T) {
////    M.A.
////}
////
////func t() {
////    make(.get)
////}
//
//struct Path {
//    let value: String
//
//    init(_ value: String) {
//        self.value = value
//    }
//}
//
//struct Response<T> {
//
//}
//
////class Request<T> {
////    fileprivate func perform(a: A, b: B) -> T {
////        fatalError()
////    }
////}
//
////class Call1<T>: Request<T> {
////    func enqueue(_ callback: @escaping (Response<T>) -> Void) -> T {
////        fatalError()
////    }
////}
////
////class Call2<U, T>: Request<T> {
////    func enqueue(_ x: U, _ callback: @escaping (Response<T>) -> Void) -> T {
////        fatalError()
////    }
////}
//
//class Call<T> {
//    func cancel() {
//
//    }
//}
//
//class Request<A, T> {
//    func enqueue(_ args: A, _ callback: @escaping (Response<T>) -> Void) -> Call<T> {
//        fatalError()
//    }
//}
//
//class ReactiveRequest<A, T> {
//    let request: Request<A, T>
//
//    init(request: Request<A, T>) {
//        self.request = request
//    }
//
//    func connect(to button: UIButton, argsProvider: @escaping () -> A) {
//        let call = request.enqueue(argsProvider()) { (response) in
//
//        }
//    }
//}
//
//protocol ReactiveRequestProto {
//    associatedtype A
//    associatedtype T
//    var reactive: ReactiveRequest<A, T> { get }
//}
//
//extension Request: ReactiveRequestProto {
//    var reactive: ReactiveRequest<A, T> {
//        return ReactiveRequest(request: self)
//    }
//}
//
////extension Call3 where A == Void {
////    func enqueue(body: B, _ callback: @escaping (Response<T>) -> Void) -> T {
////        fatalError()
////    }
////}
////
////extension Call3 where B == Void {
////    func enqueue(args: A, _ callback: @escaping (Response<T>) -> Void) -> T {
////        fatalError()
////    }
////}
////
////extension Call3 where A == Void, B == Void {
////    func enqueue(_ callback: @escaping (Response<T>) -> Void) -> T {
////        fatalError()
////    }
////}
//
////extension Call where A == Void, B == Void {
////    func perform() -> T {
////        fatalError()
////    }
////}
////
////extension Call where A == Void {
////    func perform(_ b: B) -> T {
////        fatalError()
////    }
////}
////
////extension Call where B == Void {
////    func perform(_ a: A) -> T {
////        fatalError()
////    }
////}
//
//class DoThing {
//    func make<A, B, R>(_ method: Method, args: A, body: B.Type, response: R.Type) -> Request<(A, B), R> {
//        fatalError()
//    }
//
//    func make<B, R>(_ method: Method, body: B.Type, response: R.Type) -> Request<B, R> {
//        fatalError()
//    }
//
//    func make<A, R>(_ method: Method, args: A, response: R.Type) -> Request<A, R> {
//        fatalError()
//    }
//
//    func make<R>(_ method: Method, response: R.Type) -> Request<Void, R> {
//        fatalError()
//    }
//
////    func make<A, B>(_ method: Method<A>, body: B.Type) -> Request<(A, B), Void> {
////        fatalError()
////    }
////
////    func make<B>(_ method: Method<Void>, body: B.Type) -> Request<B, Void> {
////        fatalError()
////    }
////
////    func make<A>(_ method: Method<A>) -> Request<A, Void> {
////        fatalError()
////    }
////
////    func make(_ method: Method<Void>) -> Request<Void, Void> {
////        fatalError()
////    }
//}
////
////class DoThing2 {
////    func make<A, B, R>(_ method: Method, args: A, body: B.Type, response: R.Type) -> Call3<A, B, R> {
////        fatalError()
////    }
////
////    func make<B, R>(_ method: Method, args: Void, body: B.Type, response: R.Type) -> Call2<B, R> {
////        fatalError()
////    }
////
////    func make<A, R>(_ method: Method, args: A, body: Void, response: R.Type) -> Call2<A, R> {
////        fatalError()
////    }
////
////    func make<R>(_ method: Method, args: Void, body: Void, response: R.Type) -> Call1<R> {
////        fatalError()
////    }
////}
//
////class DoThing3 {
////    func make<A, B, R>(_ method2: Method2<A>, body: B.Type, response: R.Type) -> Call3<A, B, R> {
////        fatalError()
////    }
//
////    func make<B, R>(_ method1: Method2<Void>, body: B.Type, response: R.Type) -> Call3<Void, B, R> {
////        fatalError()
////    }
////
////    func make<A, R>(_ method2: Method2<A>, body: Void, response: R.Type) -> Call3<A, Void, R> {
////        fatalError()
////    }
////
////    func make<R>(_ method1: Method2<Void>, body: Void, response: R.Type) -> Call3<Void, Void, R> {
////        fatalError()
////    }
////}
//
//struct Header {
//    init(key: String, value: String) {
//
//    }
//
//    struct Authorization {
//
//    }
//
//    init() {
//
//    }
//
//
//
////    static func authorization(add: String) -> Header {
////
////    }
//}
//
//protocol RequestApplyable {
//
//    func apply(to request: inout URLRequest)
//}
//
//extension URLRequest {
//
//    enum Method: String, RequestApplyable {
//
//        case get
//        case post
//
//
//        func apply(to request: inout URLRequest) {
//            request.httpMethod = self.rawValue.uppercased()
//        }
//    }
//}
//
//extension URL {
//    var components: URLComponents? {
//        return URLComponents(url: self, resolvingAgainstBaseURL: true)
//    }
//}
//
//extension URLRequest {
//    var urlComponents: URLComponents? {
//        get {
//            return url?.components
//        }
//        set {
//            url = newValue?.url
//        }
//    }
//}
//
//class Header2: RequestApplyable {
//
//    var name: String
//    var value: String
//
//    init(_ name: String, value: String) {
//
//        self.name = name
//        self.value = value
//    }
//
//    class Authorization: Header2 {
//
//        init(addToToken: String) {
//
//            super.init(Authorization.name, value: "Token \(addToToken)")
//
//        }
//
//        init(set: String) {
//
//            super.init(Authorization.name, value: set)
//        }
//
//        static var name = "Authorization"
//    }
//
//    func addToValue(_ str: String) {}
//
//    func apply(to request: inout URLRequest) {
//        // set header
//    }
//}
//
//struct Query2<Args>: RequestApplyable {
//
//    var args: Args
//
//    func apply(to request: inout URLRequest) {
//
////        let queryItems = request.urlComponents?.queryItems ?? []
////
////        let args = [args]
////
////        for arg in args {
////
////
////
////        }
//
//
//    }
//
//}
//
//class Path2<Args>: RequestApplyable {
//
//    var args: Args
//
//    init(_ args: Args) {
//        self.args = args
//    }
//
//    func apply(to request: inout URLRequest) {
//
////        let components = request.url?.components
////
////        guard
////            var path = components?.path,
////            let range = components?.rangeOfPath
////        else {
////            fatalError("URLRequest: \(request) has no path")
////        }
////
////        // Mirror args
////        let args = [self.args]
////
////        for arg in args {
////
////            path = String.init(format: path, "\(arg)")
////
////        }
////
////        var urlString = request.url!.absoluteString
////
////        urlString.replaceSubrange(range, with: path)
////
////        request.url = URL(string: urlString)
////
////        precondition(request.url != nil, "Failed to replace path component with: \(path)")
//
//    }
//
//
//}
//
//
//class Request2<Args, R> {
//
//    init(endpoint: String, method: URLRequest.Method, args: Args.Type = Args.self, response: R.Type = R.self) {
//
//    }
//
//    func enqueue(_ args: Args, callback: Int) {}
//
//}
//
//class MagicClass {
//
//}
//
////func MC(value: String) -> MagicClass.Type {
////
////}
//
//func a() {
//    class Person {
//
//    }
//
//    let t = DoThing()
//    let r = { () -> Request<Path, Void> in
//        let r = t.make(.get("path/{id}/"), args: Path("id"), response: Void.self)
////        r.timeout = 90
//        return r
//    }()
//
////    class User {}
////    t.make(.get("users/"), response: [User].self)
////    t.make
//
////    t.make(.get("users/"), args: (Path("id"), Query("id")))
//
//    let anything = (Path, Path, URL, Header.Authorization, Person).self
//
////    var function: ((Path, Path, URL, Header, Body(Person, Encoder.Type = Body.defaultEncoder))) -> ()
////
////    function((Path, Path, URL, , Person))
//
//
//
////    let thing3 = DoThing3()
////    let re3 = thing3.make(
////        .get("users/{id}/{another}/?users={which user}"),
////        args: (Path(), Path(), URL(), Header(), Person.Type),
////        response: Void.self
////    )
//
//    ///
//
//
//
//    //    re3.enqueue((Path(""), Header("authorization", value: "Token {{token}}"), Body(Person()))) { (response) in
////
////    }
////
////    re3.enqueue(args: Path(""), body: Person()) { (response) in
////
////    }
//
//    ///
//
////    re3.enqueue() { (response) in
////
////    }
////
////    re3.enqueue(args: (), body: ()) { (response) in
////
////    }
//
////    let t = DoThing()
////    let r = t.make(.delete("users/{id}"), args: Path("id"), response: Void.self)
////    t.make(.delete("users/3/"), body: Person.self).enqueue(Person()) { (response) in
////
////    }
////    let getPeople = t.make(.get("users/"), response: [Person].self)
////    getPeople.enqueue { (response) in
////
////    }
////
////
////    let t2 = DoThing2()
////    let r2 = t2.make(.delete("users/{id}"), args: Path("id"), body: (), response: Void.self)
////    t2.make(.delete("users/3/"), args: (), body: Person.self, response: Void.self).enqueue(Person()) { (response) in
////
////    }
////
////    t.make(<#T##method: Method##Method#>, args: <#T##A#>, body: <#T##B.Type#>, response: <#T##R.Type#>)
////    let getPeople2 = t2.make(.get("users/"), args: (), body: (), response: [Person].self)
////    getPeople2.perform()
//}
//
//
//
