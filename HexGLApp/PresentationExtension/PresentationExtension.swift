// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import XWalkView

public class PresentationExtension: XWalkExtension {

    var remoteWindows: Array<UIWindow> = []
    var remoteViewController: RemoteViewController?

    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenDidConnect", name: UIScreenDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenDidDisconnect", name: UIScreenDidDisconnectNotification, object: nil)
    }

    public override func didGenerateStub(stub: String!) -> String! {
        var bundle = NSBundle(forClass: self.dynamicType)
        var className = NSStringFromClass(self.dynamicType)
        if (className == nil) {
            return stub
        }

        if countElements(className.pathExtension) > 0 {
            className = className.pathExtension
        }
        if let path = bundle.pathForResource(className, ofType: "js") {
            if let content = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                for var index = stub.endIndex;
                    index != stub.startIndex;
                    index = index.predecessor() {
                        if stub[index.predecessor()] == "}" {
                            return stub.substringToIndex(index.predecessor()) + content + stub.substringFromIndex(index.predecessor())
                        }
                }
                return stub.stringByAppendingString(content)
            }
        }
        return stub
    }

    func createWindowForScreen(screen: UIScreen) -> UIWindow {
        var window: UIWindow? = nil
        for win in remoteWindows {
            if win.screen == screen {
                window = win
            }
        }
        if window == nil {
            window = UIWindow(frame: screen.bounds)
            window?.screen = screen
            self.remoteWindows.append(window!)
        }
        return window!
    }

    func addViewControllerToWindow(controller: UIViewController, window: UIWindow) {
        window.rootViewController = controller
        window.hidden = false
    }

    func screenDidConnect(notification: NSNotification) {
        if let screen = notification.object as? UIScreen {
            println("screenDidConnect")
            /*
            var window = createWindowForScreen(screen)
            var viewController = RemoteViewController()
            addViewControllerToWindow(viewController, window: window)
            */
        }
    }

    func screenDidDisconnect(notification: NSNotification) {
        if let screen = notification.object as? UIScreen {
            println("screenDidDisconnect")
            /*
            for var i = 0; i < remoteWindows.count; ++i {
            if remoteWindows[i].screen == screen {
            remoteWindows.removeAtIndex(i)
            return
            }
            }
            */
        }
    }

    func jsfunc_requestShow(requestId: NSNumber, url: String, baseUrl: String) {
        println("js_requestShow called, with requestId:\(requestId), url:\(url), baseUrl:\(baseUrl)")

        var screens = UIScreen.screens()
        /*
        for obj in screens {
        var window = createWindowForScreen(obj as UIScreen)
        var viewController = RemoteViewController(baseUrl: baseUrl, url: url)
        addViewControllerToWindow(viewController, window: window)
        }
        */
        var screen: UIScreen = UIScreen.screens()[1] as UIScreen
        var window = createWindowForScreen(screen)
        var controller = RemoteViewController()
        addViewControllerToWindow(controller, window: window)

        controller.loadURL(NSURL(string: baseUrl.stringByAppendingPathComponent(url))!)
        self.remoteViewController = controller

        var event = [
            "type": "ShowSucceeded",
            "requestId": requestId,
            "data": 1
        ]
        super.invokeJavaScript(".dispatchEvent", arguments: [event])
    }

    func jsfunc_postMessage(viewId: NSNumber, message: String, scope: String) {
        println("js_postMessage with viewId:\(viewId), message:\(message), scope:\(scope)")
        remoteViewController?.sendMessage(message)
    }

    func jsfunc_close(viewId: NSNumber) {
    }

}
