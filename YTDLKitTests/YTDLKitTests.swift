//
//  YTDLKitTests.swift
//  YTDLKitTests
//
//  Created by Danylo Kostyshyn on 20.07.2022.
//

import XCTest
@testable import YTDLKit

class YTDLKitTests: XCTestCase {

    func testPython() {
        let ytdl = YTDL.shared
        XCTAssertEqual(ytdl.helloWorld(), 42)
    }

}
