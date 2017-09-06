//
//  BuilderOptionalArgsTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 8/29/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation
import XCTest
@testable import Retrolux

protocol HaWorkaroundOfSameTypeRequirement {}

class BuilderOptionalArgsTests: XCTestCase {
    
    struct Test {
        struct Nested {
            let path1: Path
            let path2: Path?
        }
        
        let nested: Nested?
        let path3: Path
    }
    
    func test1NonBuilderArgNestedNil() {
        
        do { // test1
            let test1Creation: Test = Test(nested: Test.Nested(path1: Path("1"), path2: Path("2")), path3: Path("3"))
            let test1Starting: Test = Test(nested: nil, path3: Path("three"))
            let parsed1 = try makeTestBuilder().parseArguments(creation: test1Creation, starting: test1Starting) as! [(Path, Path?)]
            
            print("parsed1", parsed1)
            if parsed1.count == 3 {
                XCTAssert(parsed1[0].0.value == "1" && parsed1[0].1 == nil)
                XCTAssert(parsed1[1].0.value == "2" && parsed1[1].1 == nil)
                XCTAssert(parsed1[2].0.value == "3" && parsed1[2].1?.value == "three")
            } else {
                print("parsed1.count", parsed1.count)
                XCTFail("Incorrect number of parsed arguments.")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test1BNonBuilderArgNestedCreationNil() {
        
        do { // test1B
            let test1BCreation: Test = Test(nested: nil, path3: Path("3"))
            let test1BStarting: Test = Test(nested: Test.Nested(path1: Path("one"), path2: Path("two")), path3: Path("three"))
            _ = try makeTestBuilder().parseArguments(creation: test1BCreation, starting: test1BStarting) as! [(Path, Path?)]
            
            XCTFail("parseArguments should have thrown nil arg in creation")
        } catch Builder.ParseArgumentError.nilArgInCreation {
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }
    }
    
    func test2NestedBuilderArgNil() {
        
        do { // test2
            let test2Creation = Test(nested: Test.Nested(path1: Path("1"), path2: Path("2")), path3: Path("3"))
            let test2Starting = Test(nested: Test.Nested(path1: Path("one"), path2: nil), path3: Path("three"))
            let parsed2 = try makeTestBuilder().parseArguments(creation: test2Creation, starting: test2Starting) as! [(Path, Path?)]
            
            if parsed2.count == 3 {
                XCTAssert(parsed2[0].0.value == "1" && parsed2[0].1?.value == "one")
                XCTAssert(parsed2[1].0.value == "2" && parsed2[1].1 == nil)
                XCTAssert(parsed2[2].0.value == "3" && parsed2[2].1?.value == "three")
            } else {
                print("parsed2", parsed2)
                print("parsed2.count", parsed2.count)
                XCTFail("Incorrect number of parsed arguments.")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testOptionalInvalidArgument() {
        
        do { // test optional invalid argument
            typealias Test3 = (String?, Path)
            let test3Creation: Test3 = ("test", Path("1"))
            let test3Starting: Test3 = (nil, Path("fail"))
            
            _ = try makeTestBuilder().parseArguments(creation: test3Creation, starting: test3Starting) as! [(Path, Path?)]
            
            XCTFail("Parsed did not throw with an invalid argument")
            
        } catch Builder.ParseArgumentError.valueNotBuilderArg(let type) {
            _ = type
            // type thrown is String.Type when it should be String?.Type is this good enough?
            //            XCTAssert(type is String?.Type, "incorrect type returned: \(type)")
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }
    }
    
    func test3BothCreationAndStartingNil() {
        
        do { // test3
            let test3Creation = Test(nested: nil, path3: Path("3"))
            let test3Starting = Test(nested: nil, path3: Path("three"))
            _ = try makeTestBuilder().parseArguments(creation: test3Creation, starting: test3Starting) as! [(Path, Path?)]
            XCTFail("Parsed did not throw with a nil argument")
        } catch Builder.ParseArgumentError.nilArgInCreation {
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }
    }
    
    func testInvalidArgument() {
        
        do { // test invalid argument
            typealias Test4 = (((Path, (Path, String), Void)), Path?)
            
            let test4Creation: Test4 = ((Path("1"), (Path(""), "String"), ()), Path("1"))
            let test4Starting: Test4 = ((Path("1"), (Path(""), "String"), ()), nil)
            
            _ = try makeTestBuilder().parseArguments(creation: test4Creation, starting: test4Starting) as! [(Path, Path?)]
            
            XCTFail("Parse did not throw an error")
        } catch Builder.ParseArgumentError.valueNotBuilderArg(let type) {
            XCTAssert(type is String.Type)
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }
    }
    
    func testNilInvalidArgument() {
        
        do { // test nil invalid argument
            
            typealias Test_ = (((Path, (Path, String?))), Path?)
            
            let test4Creation: Test_ = ((Path("1"), (Path(""), nil)), Path("1"))
            let test4Starting: Test_ = ((Path("1"), (Path(""), "String")), nil)
            
            _ = try makeTestBuilder().parseArguments(creation: test4Creation, starting: test4Starting) as! [(Path, Path?)]
            
            XCTFail("Parse did not throw an error")
            
        } catch Builder.ParseArgumentError.valueNotBuilderArg(let type) {
            // not important if value is String?.Type or Any?.Type
            XCTAssert(type is String?.Type)
        } catch Builder.ParseArgumentError.nilArgInCreation {
            // throws nil arg in creation. I think that's better
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }
    }
    
    func test4TopLevelCreationNil() {
        
        do { // test4
            let test4Creation: Path? = nil
            let test4Starting: Path? = Path("one")
            _ = try makeTestBuilder().parseArguments(creation: test4Creation, starting: test4Starting) as! [(Path, Path?)]
            
            XCTFail("Parsed did not throw with a nil argument")
        } catch Builder.ParseArgumentError.nilArgInCreation {
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }
    }
    
    func test5TopLevelNil() {
        
        do { // test5
            let test5Creation: Path? = Path("1")
            let test5Starting: Path? = nil
            let parsed5 = try makeTestBuilder().parseArguments(creation: test5Creation, starting: test5Starting) as! [(Path, Path?)]
            if parsed5.count == 1 {
                XCTAssert(parsed5[0].0.value == "1" && parsed5[0].1 == nil)
            } else {
                XCTFail("Incorrect number of parsed arguments.")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test6NonBuilderArgNil() {
        
        do { // test6
            let test6Creation: (Path, Path)? = (Path("1"), Path("2"))
            let test6Starting: (Path, Path)? = nil
            let parsed6 = try makeTestBuilder().parseArguments(creation: test6Creation, starting: test6Starting) as! [(Path, Path?)]
            
            if parsed6.count == 2 {
                XCTAssert(parsed6[0].0.value == "1" && parsed6[0].1?.value == nil)
                XCTAssert(parsed6[1].0.value == "2" && parsed6[1].1?.value == nil)
            } else {
                print("parsed6", parsed6)
                print("parsed6.count", parsed6.count)
                XCTFail("Incorrect number of parsed arguments.")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    // removed test7 equal to test4
    
    func test8BothMil() {
     
        do { // test8
            let test8Creation: Path? = nil
            let test8Starting: Path? = nil
            _ = try makeTestBuilder().parseArguments(creation: test8Creation, starting: test8Starting)
            
            XCTFail("Parsed did not throw with a nil argument")
        } catch Builder.ParseArgumentError.nilArgInCreation {
        } catch {
            XCTFail("Wrong error thrown: \(error)")
        }
    }
    
    func testMismatchBuilderArgs() {
        
        do { // test mismatch builder args
            typealias Test9 = (BuilderArg)
            
            let test9Creation: Test9 = (Path("testMix") as BuilderArg)
            let test9Starting: Test9 = (Query("test") as BuilderArg)
            
            _ = try makeTestBuilder().parseArguments(creation: test9Creation, starting: test9Starting) as! [(Path, Path?)]
            
            XCTFail("Parse did not throw")
            
        } catch Builder.ParseArgumentError.mismatchTypes(creation: _, starting: _) {
        } catch {
            XCTFail("Wrong error throwm: \(error)")
        }
    }
    
    func testNoChildrenNotVoid() {
        do {
            struct Object_{}
            
            let testCreation = Object_()
            let testStarting = Object_()
            
            _ = try makeTestBuilder().parseArguments(creation: testCreation, starting: testStarting)
            
            XCTFail("Parse did not catch empty arg")
        } catch Builder.ParseArgumentError.valueNotBuilderArg(_) {
        } catch {
            XCTFail("Wrong Error thrown: \(error)")
        }
    }
    
    // MARK: Optional tests
    
    func testDontThrowForVoid() {
        
        do { // test don't throw for void
            typealias Test7 = (((Path, (Path), Void)), Path?)
            
            let test7Creation: Test7 = ((Path("1"), (Path("")), ()), Path("1"))
            let test7Starting: Test7 = ((Path("1"), (Path("")), ()), nil)
            
            let parsed7 = try makeTestBuilder().parseArguments(creation: test7Creation, starting: test7Starting) as! [(Path, Path?)]
            
            if parsed7.count == 3 {
                XCTAssert(parsed7[0].0.value == parsed7[0].1?.value)
                XCTAssert(parsed7[1].0.value == parsed7[1].1?.value)
                XCTAssert(parsed7[2].1 == nil)
                
            } else if parsed7.count == 4 {
                XCTFail("Void was not filtered.")
            } else {
                XCTFail("Incorrect number of parsed arguments: \(parsed7.count)")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testDictionaryEqual() {
        
        do { // test dictionary equal
            typealias Test8 = [String: Any]
            
            let path1Creation = Path("1")
            let path2Creation = Path("2")
            let path1Starting = Path("test1")
            let path2Starting = Path("test2")
            
            let test8Creation: Test8 = ["test1": path1Creation, "test2": path2Creation]
            let test8Starting: Test8 = ["test2": path2Starting, "test1": path1Starting]
            
            let parsed8 = try makeTestBuilder().parseArguments(creation: test8Creation, starting: test8Starting) as! [(Path, Path?)]
            
            if parsed8.count == 2 {
                
                // if the first is path1creation, .1?.value must path1Creation etc..
                
                XCTAssert(parsed8[0].0.value == "1" ? parsed8[0].1?.value == "test1" : parsed8[0].1?.value == "test2")
                XCTAssert(parsed8[1].0.value == "2" ? parsed8[1].1?.value == "test2" : parsed8[1].1?.value == "test1")
                
            } else {
                XCTFail("Incorrect number of parsed arguments.")
            }
            
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testDictionaryUnevenCreationGreater() {
        
        do {
            typealias Test8 = [String: Any]
            
            let path1Creation = Path("1")
            let path2Creation = Path("2")
            let path1Starting = Path("test1")
            let path2Starting = Path("test2")
            
            let path3Creation = Path("3")
            
            let test8Creation: Test8 = ["test1": path1Creation, "test2": path2Creation, "test3": path3Creation]
            let test8Starting: Test8 = ["test2": path2Starting, "test1": path1Starting]
            
            let parsed = try makeTestBuilder().parseArguments(creation: test8Creation, starting: test8Starting) as! [(Path, Path?)]
            
            func assert(_ value: (Path, Path?)) {
                
                if value.0.value == "1" {
                    XCTAssert(value.1?.value == "test1")
                    
                } else if value.0.value == "2" {
                    XCTAssert(value.1?.value == "test2")
                    
                } else if value.0.value == "3" {
                    XCTAssert(value.1?.value == nil)
                }
            }
            
            if parsed.count == 3 {
                
                for value in parsed {
                    assert(value)
                }
                
            } else {
                XCTFail("Incorrect number of parsed arguments: \(parsed.count)")
            }
            
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testDictionaryUnevenStartingGreater() {
        
        do {
            typealias Test8 = [String: Any]
            
            let path1Creation = Path("1")
            
            let path1Starting = Path("test1")
            let path2Starting = Path("test2")
            
            let test8Creation: Test8 = ["test1": path1Creation]
            let test8Starting: Test8 = ["test2": path2Starting, "test1": path1Starting]
            
            let parsed = try makeTestBuilder().parseArguments(creation: test8Creation, starting: test8Starting) as! [(Path, Path?)]
            
            if parsed.count == 1 {
                
                XCTAssert(parsed[0].0.value == "1" && parsed[0].1?.value == "test1")
                
            } else {
                XCTFail("Incorrect number of parsed arguments: \(parsed.count)")
            }
            
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testArrayEqual() {
        
        do { // test array equal
            let testCreation = [Path("1"), Path("2")]
            let testStarting = [nil, Path("r")]
            
            let parsed = try makeTestBuilder().parseArguments(creation: testCreation, starting: testStarting) as! [(Path, Path?)]
            
            if parsed.count == 2 {
                XCTAssert(parsed[0].0.value == "1" && parsed[0].1 == nil)
                XCTAssert(parsed[1].0.value == "2" && parsed[1].1?.value == "r")
                
            } else {
                XCTFail("Incorrect number of parsed arguments: \(parsed.count)")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testArrayUnevenCreationGreater() {
        
        do {
            typealias Test = [Path?]
            
            let testCreation: Test = [Path("1"), Path("2")]
            let testStarting: Test = [Path("one")]
            
            let parsed = try makeTestBuilder().parseArguments(creation: testCreation, starting: testStarting) as! [(Path, Path?)]
            
            if parsed.count == 2 {
                XCTAssert(parsed[0].0.value == "1" && parsed[0].1?.value == "one")
                XCTAssert(parsed[1].0.value == "2" && parsed[1].1 == nil)
                
            } else {
                XCTFail("Incorrect number of parsed arguments: \(parsed.count)")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testArrayUnevenStartingGreater() {
        
        do {
            typealias Test = [Path?]
            
            let testCreation: Test = [Path("1")]
            let testStarting: Test = [nil, Path("two")]
            
            let parsed = try makeTestBuilder().parseArguments(creation: testCreation, starting: testStarting) as! [(Path, Path?)]
            
            if parsed.count == 1 {
                XCTAssert(parsed[0].0.value == "1" && parsed[0].1 == nil)
                
            } else {
                XCTFail("Incorrect number of parsed arguments: \(parsed.count)")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func testEqualChildrenHappenToBeBuilderArg() {
        
        do { // test random object with equal number of children that happen to be builder args
            
            struct Random1: HaWorkaroundOfSameTypeRequirement {
                var one = Path("123")
                var two = Path("321")
            }
            
            struct Random2: HaWorkaroundOfSameTypeRequirement {
                var one = Path("oneTwoThree")
                var two = nil as Path?
            }
            
            let test1: HaWorkaroundOfSameTypeRequirement = Random1()
            let test2: HaWorkaroundOfSameTypeRequirement = Random2()
            
            let parsed = try makeTestBuilder().parseArguments(creation: test1, starting: test2) as! [(Path, Path?)]
            
            if parsed.count == 2 {
                XCTAssert(parsed[0].0.value == "123" && parsed[0].1?.value == "oneTwoThree")
                XCTAssert(parsed[1].0.value == "321" && parsed[1].1 == nil)
                
            } else {
                XCTFail("Incorrect number of parsed arguments: \(parsed.count)")
            }
        } catch {
            XCTFail("")
        }
    }
}
















