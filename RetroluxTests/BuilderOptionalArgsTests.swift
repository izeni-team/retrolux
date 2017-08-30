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

class BuilderOptionalArgsTests: XCTestCase {
    
//    func testArgs() {
//        typealias Value = (Int, String, (Int, String)?)
//        let value1: Value = (1,"test", (2, "test2"))
//
//        func iterate(with value1: Any, value2: Any) -> Any {
//
//            switch value {
//            case is Int: return value1 as! Int + value2 as! Int
//            case is String:
//
//            }
//
//
//            if let value = value as? Int {
//
//            }
//        }
//
//        print(iterate(with: value1))
//    }
//
    func testArgumentParser() {
        struct Test {
            struct Nested {
                let path1: Path
                let path2: Path?
            }
            
            let nested: Nested?
            let path3: Path
        }
        
        let test1Creation: Test = Test(nested: Test.Nested(path1: Path("1"), path2: Path("2")), path3: Path("3"))
        let test1Starting: Test = Test(nested: nil, path3: Path("three"))
        let parsed1 = try! makeTestBuilder().parseArguments(creation: test1Creation, starting: test1Starting) as! [(Path?, Path?)]
        if parsed1.count == 3 {
            XCTAssert(parsed1[0].0?.value == "1" && parsed1[0].1 == nil)
            XCTAssert(parsed1[1].0?.value == "2" && parsed1[1].1 == nil)
            XCTAssert(parsed1[2].0?.value == "3" && parsed1[2].1?.value == "three")
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test1BCreation: Test = Test(nested: nil, path3: Path("3"))
        let test1BStarting: Test = Test(nested: Test.Nested(path1: Path("one"), path2: Path("two")), path3: Path("three"))
        let parsed1B = try! makeTestBuilder().parseArguments(creation: test1BCreation, starting: test1BStarting) as! [(Path?, Path?)]
        if parsed1B.count == 3 {
            XCTAssert(parsed1B[0].0 == nil && parsed1B[0].1?.value == "one")
            XCTAssert(parsed1B[1].0 == nil && parsed1B[1].1?.value == "two")
            XCTAssert(parsed1B[2].0?.value == "3" && parsed1B[2].1?.value == "three")
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test2Creation = Test(nested: Test.Nested(path1: Path("1"), path2: Path("2")), path3: Path("3"))
        let test2Starting = Test(nested: Test.Nested(path1: Path("one"), path2: nil), path3: Path("three"))
        let parsed2 = try! makeTestBuilder().parseArguments(creation: test2Creation, starting: test2Starting) as! [(Path?, Path?)]
        if parsed2.count == 3 {
            XCTAssert(parsed2[0].0?.value == "1" && parsed2[0].1?.value == "one")
            XCTAssert(parsed2[1].0?.value == "2" && parsed2[1].1 == nil)
            XCTAssert(parsed2[2].0?.value == "3" && parsed2[2].1?.value == "three")
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test3Creation = Test(nested: nil, path3: Path("3"))
        let test3Starting = Test(nested: nil, path3: Path("three"))
        let parsed3 = try! makeTestBuilder().parseArguments(creation: test3Creation, starting: test3Starting) as! [(Path?, Path?)]
        if parsed3.count == 1 {
            XCTAssert(parsed3[0].0?.value == "3" && parsed3[0].1?.value == "three")
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test4Creation: Path? = nil
        let test4Starting: Path? = Path("one")
        let parsed4 = try! makeTestBuilder().parseArguments(creation: test4Creation, starting: test4Starting) as! [(Path?, Path?)]
        if parsed4.count == 1 {
            XCTAssert(parsed4[0].0 == nil && parsed4[0].1?.value == "one")
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test5Creation: Path? = Path("1")
        let test5Starting: Path? = nil
        let parsed5 = try! makeTestBuilder().parseArguments(creation: test5Creation, starting: test5Starting) as! [(Path?, Path?)]
        if parsed5.count == 1 {
            XCTAssert(parsed5[0].0?.value == "1" && parsed5[0].1 == nil)
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test6Creation: (Path, Path)? = (Path("1"), Path("2"))
        let test6Starting: (Path, Path)? = nil
        let parsed6 = try! makeTestBuilder().parseArguments(creation: test6Creation, starting: test6Starting) as! [(Path?, Path?)]
        if parsed6.count == 2 {
            XCTAssert(parsed6[0].0?.value == "1" && parsed6[0].1?.value == nil)
            XCTAssert(parsed6[1].0?.value == "2" && parsed6[1].1?.value == nil)
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test7Creation: Path? = nil
        let test7Starting: Path? = Path("1")
        let parsed7 = try! makeTestBuilder().parseArguments(creation: test7Creation, starting: test7Starting) as! [(Path?, Path?)]
        XCTAssert(parsed7.count == 1)
        if parsed7.count == 1 {
            XCTAssert(parsed7[0].0 == nil && parsed7[0].1?.value == "1")
        } else {
            XCTFail("Incorrect number of parsed arguments.")
        }
        
        let test8Creation: Path? = nil
        let test8Starting: Path? = nil
        let parsed8 = try! makeTestBuilder().parseArguments(creation: test8Creation, starting: test8Starting) as! [(Path?, Path?)]
        XCTAssert(parsed8.count == 0)
    }
}
