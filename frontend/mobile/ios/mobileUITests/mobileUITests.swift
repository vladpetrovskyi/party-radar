//
//  mobileUITests.swift
//  mobileUITests
//
//  Created by Petrovskyi, Vladyslav on 07.02.24.
//

import XCTest

final class mobileUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        app.otherElements["Location\nTab 2 of 3"].tap()
        app.otherElements["🎛️ Main room"].tap()
        
        let element2 = app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
        let element = element2.children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 2).tap()
        element.children(matching: .button).element(boundBy: 2).tap()
        app.staticTexts["Profile\nTab 3 of 3"].tap()
        
        let staticText = app.staticTexts["5 \nFriends\nTab 2 of 3"]
        staticText.tap()
        app.staticTexts["1 \nRequest\nTab 3 of 3"].tap()
        app.buttons["Show menu"].tap()
        
        let dismissMenuStaticText = app.staticTexts["Dismiss menu"]
        dismissMenuStaticText.tap()
        staticText.tap()
        element2.children(matching: .other).element(boundBy: 4).children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1).buttons["Show menu"].tap()
        dismissMenuStaticText.tap()
        app.staticTexts["4 \nPosts\nTab 1 of 3"].tap()
        app.staticTexts["Groove Garden\nFeb 6, 22:54\nMain room 🎛️\nDance floor 👯"].tap()
        
        let dismissStaticText = app.staticTexts["Dismiss"]
        dismissStaticText.swipeUp()
        dismissStaticText.swipeDown()
        
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
