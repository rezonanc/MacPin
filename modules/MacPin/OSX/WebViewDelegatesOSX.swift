/// MacPin WebViewDelegates
///
/// Handle modal & interactive webview prompts and errors using OSX widgets

import WebKit
import WebKitPrivates
//import Async

extension WebViewControllerOSX {

	func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
		let alert = NSAlert()
		alert.messageText = webView.title ?? ""
		alert.addButton(withTitle: "Dismiss")
		alert.informativeText = message
		alert.icon = webview.favicon.icon
		alert.alertStyle = .informational // .Warning .Critical
		displayAlert(alert) { (response: NSApplication.ModalResponse) -> Void in completionHandler() }
	}

	func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
		let alert = NSAlert()
		alert.messageText = webView.title ?? ""
		alert.addButton(withTitle: "OK")
		alert.addButton(withTitle: "Cancel")
		alert.informativeText = message
		alert.icon = NSApplication.shared.applicationIconImage
		displayAlert(alert) { (response: NSApplication.ModalResponse) -> Void in completionHandler(response == .alertFirstButtonReturn ? true : false) }
	}

	func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
		let alert = NSAlert()
		alert.messageText = webView.title ?? ""
		alert.addButton(withTitle: "Submit")
		alert.informativeText = prompt
		alert.icon = NSApplication.shared.applicationIconImage
		let input = NSTextField(frame: NSMakeRect(0, 0, 200, 24))
		input.stringValue = defaultText ?? ""
		input.isEditable = true
 		alert.accessoryView = input
		displayAlert(alert) { (response: NSApplication.ModalResponse) -> Void in completionHandler(input.stringValue) }
	}
}

extension WebViewControllerOSX {

	// https://github.com/WebKit/webkit/commit/fa99fc8295905850b2b9444ba019a7250996ee7d
	@objc func webView(_ webView: WKWebView, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge,
		completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

/*
FIXME: `completionHandler(.PerformDefaultHandling, nil)` sometimes causes missing selector exceptions in com.apple.WebKit.Networking
.PerformDefaultHandling appears to be optional
https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Protocols/NSURLAuthenticationChallengeSender_Protocol/index.html#//apple_ref/occ/intfm/NSURLAuthenticationChallengeSender/rejectProtectionSpaceAndContinueWithChallenge:
WebKit bug in WebCore? workaround: http://stackoverflow.com/a/27604335/3878712

Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[WebCoreAuthenticationClientAsChallengeSender performDefaultHandlingForAuthenticationChallenge:]: unrecognized selector sent to instance 0x7fd12dc0a4b0'
abort() called
terminating with uncaught exception of type NSException

Application Specific Backtrace 1:
0   CoreFoundation                      0x00007fff9d28aae2 __exceptionPreprocess + 178
1   libobjc.A.dylib                     0x00007fff94a06f7e objc_exception_throw + 48
2   CoreFoundation                      0x00007fff9d28db9d -[NSObject(NSObject) doesNotRecognizeSelector:] + 205
3   CoreFoundation                      0x00007fff9d1c6412 ___forwarding___ + 514
4   CoreFoundation                      0x00007fff9d1c6188 _CF_forwarding_prep_0 + 120
5   WebKit                              0x00007fff9628e348 _ZN6WebKit21AuthenticationManager40performDefaultHandlingForSingleChallengeEy + 104
6   WebKit                              0x00007fff9628e291 _ZN6WebKit21AuthenticationManager22performDefaultHandlingEy + 73
7   WebKit                              0x00007fff9628f782 _ZN6WebKit21AuthenticationManager17didReceiveMessageERN3IPC10ConnectionERNS1_14MessageDecoderE + 196
8   WebKit                              0x00007fff962cb26b _ZN3IPC18MessageReceiverMap15dispatchMessageERNS_10ConnectionERNS_14MessageDecoderE + 113
9   WebKit                              0x00007fff962efb22 _ZN6WebKit14NetworkProcess17didReceiveMessageERN3IPC10ConnectionERNS1_14MessageDecoderE + 28
10  WebKit                              0x00007fff962924ba _ZN3IPC10Connection15dispatchMessageENSt3__110unique_ptrINS_14MessageDecoderENS1_14default_deleteIS3_EEEE + 102
11  WebKit                              0x00007fff962949e6 _ZN3IPC10Connection18dispatchOneMessageEv + 114
12  JavaScriptCore                      0x00007fff9dcffd55 _ZN3WTF7RunLoop11performWorkEv + 437
13  JavaScriptCore                      0x00007fff9dd00432 _ZN3WTF7RunLoop11performWorkEPv + 34
14  CoreFoundation                      0x00007fff9d19a5c1 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 17
15  CoreFoundation                      0x00007fff9d18c41c __CFRunLoopDoSources0 + 556
16  CoreFoundation                      0x00007fff9d18b93f __CFRunLoopRun + 927
17  CoreFoundation                      0x00007fff9d18b338 CFRunLoopRunSpecific + 296
18  Foundation                          0x00007fff8975fe61 -[NSRunLoop(NSRunLoop) runMode:beforeDate:] + 270
19  Foundation                          0x00007fff897d1afd -[NSRunLoop(NSRunLoop) run] + 74
20  libxpc.dylib                        0x00007fff936d9f42 _xpc_objc_main + 751
21  libxpc.dylib                        0x00007fff936db6bb _xpc_main_listener_event + 0
22  com.apple.WebKit.Networking         0x000000010a3adb4a com.apple.WebKit.Networking + 2890
23  libdyld.dylib                       0x00007fff926e55ad start + 1
24  ???                                 0x0000000000000001 0x0 + 1

Global Trace Buffer (reverse chronological seconds):
0.829369     CFNetwork                 	0x00007fff8eb975d3 TCP Conn 0x7fd12b503930 started
0.829369     CFNetwork                 	0x00007fff8eb975d3 TCP Conn 0x7fd12b5008f0 started
0.830387     CFNetwork                 	0x00007fff8eb9c66c TCP Conn 0x7fd12de1b5a0 trust evalulation failed: -9802
0.998347     CFNetwork                 	0x00007fff8ec58654 NSURLConnection finished with error - code -1005
0.998473     CFNetwork                 	0x00007fff8ec6774f HTTP load failed (error code: -1005 [1:57])
0.998480     CFNetwork                 	0x00007fff8ecae3c5 _CFNetworkIsConnectedToInternet returning 1, flagsValid: 1, flags: 0x2
0.999019     CFNetwork                 	0x00007fff8eceafb6 TCP Conn 0x7fd12db3a5c0 network reachability changed : setting stream error to ENOTCONN
0.999083     CFNetwork                 	0x00007fff8eceafb6 TCP Conn 0x7fd12d975de0 network reachability changed : setting stream error to ENOTCONN
0.999156     CFNetwork                 	0x00007fff8eceafb6 TCP Conn 0x7fd12de1b5a0 network reachability changed : setting stream error to ENOTCONN
1.000673     CFNetwork                 	0x00007fff8eceafb6 TCP Conn 0x7fd12b784b50 network reachability changed : setting stream error to ENOTCONN
1.000777     CFNetwork                 	0x00007fff8eceafb6 TCP Conn 0x7fd12b75b0e0 network reachability changed : setting stream error to ENOTCONN
1.000883     CFNetwork                 	0x00007fff8eceafb6 TCP Conn 0x7fd12de13ec0 network reachability changed : setting stream error to ENOTCONN
1.006806     CFNetwork                 	0x00007fff8eceafb6 TCP Conn 0x7fd12b4195f0 network reachability changed : setting stream error to ENOTCONN
1.964091     CFNetwork                 	0x00007fff8eb99937 TCP Conn 0x7fd12de1b5a0 starting SSL negotiation
1.964299     CFNetwork                 	0x00007fff8eb98303 TCP Conn 0x7fd12de1b5a0 complete. fd: 7, err: 0
1.964589     CFNetwork                 	0x00007fff8ec26b1d TCP Conn 0x7fd12de1b5a0 event 1. err: 0
1.974943     CFNetwork                 	0x00007fff8ec58654 NSURLConnection finished with error - code -1005
1.975067     CFNetwork                 	0x00007fff8ec58654 NSURLConnection finished with error - code -1005
1.995782     CFNetwork                 	0x00007fff8ec6774f HTTP load failed (error code: -1005 [1:54])
1.995903     CFNetwork                 	0x00007fff8ec6774f HTTP load failed (error code: -1005 [1:54])
1.996249     CFNetwork                 	0x00007fff8eb975d3 TCP Conn 0x7fd12de1b5a0 started
1.996308     CFNetwork                 	0x00007fff8ec58654 NSURLConnection finished with error - code -1005
1.996434     CFNetwork                 	0x00007fff8ec6774f HTTP load failed (error code: -1005 [1:54])
161.789860   CFNetwork                 	0x00007fff8eb99a5b TCP Conn 0x7fd12b75b0e0 SSL Handshake DONE
161.938375   CFNetwork                 	0x00007fff8eb99937 TCP Conn 0x7fd12b75b0e0 starting SSL negotiation
161.938480   CFNetwork                 	0x00007fff8eb98303 TCP Conn 0x7fd12b75b0e0 complete. fd: 30, err: 0
161.938564   CFNetwork                 	0x00007fff8ec26b1d TCP Conn 0x7fd12b75b0e0 event 1. err: 0
162.019969   CFNetwork                 	0x00007fff8eb975d3 TCP Conn 0x7fd12b75b0e0 started
273.938106   CFNetwork                 	0x00007fff8eb99a5b TCP Conn 0x7fd12db0c9f0 SSL Handshake DONE
274.011735   CFNetwork                 	0x00007fff8eb99937 TCP Conn 0x7fd12db0c9f0 starting SSL negotiation
274.011846   CFNetwork                 	0x00007fff8eb98303 TCP Conn 0x7fd12db0c9f0 complete. fd: 26, err: 0
274.011921   CFNetwork                 	0x00007fff8ec26b1d TCP Conn 0x7fd12db0c9f0 event 1. err: 0
274.018707   CFNetwork                 	0x00007fff8eb975d3 TCP Conn 0x7fd12db0c9f0 started
438.533544   CFNetwork                 	0x00007fff8eb99a5b TCP Conn 0x7fd12b4195f0 SSL Handshake DONE
438.869868   CFNetwork                 	0x00007fff8eb99937 TCP Conn 0x7fd12b4195f0 starting SSL negotiation
438.869997   CFNetwork                 	0x00007fff8eb98303 TCP Conn 0x7fd12b4195f0 complete. fd: 27, err: 0
438.870367   CFNetwork                 	0x00007fff8ec26b1d TCP Conn 0x7fd12b4195f0 event 1. err: 0
*/

		if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
			// Server Trust Method not implemented, reject it out of hand
			//completionHandler(.PerformDefaultHandling, nil)
			completionHandler(.rejectProtectionSpace, nil)
			return
		}
		warn("(\(challenge.protectionSpace.authenticationMethod)) [\(webView.urlstr)]")

		let alert = NSAlert()
		alert.messageText = webView.title ?? ""
		alert.addButton(withTitle: "Submit")
		alert.addButton(withTitle: "Cancel")
		alert.informativeText = "auth challenge"
		alert.icon = NSApplication.shared.applicationIconImage

		let prompts = NSView(frame: NSMakeRect(0, 0, 200, 64))

		let userbox = NSTextField(frame: NSMakeRect(0, 40, 200, 24))
		userbox.stringValue = "Enter user"
 		if let cred = challenge.proposedCredential {
			if let user = cred.user { userbox.stringValue = user }
		}
		userbox.isEditable = true

		let passbox = NSTextField(frame: NSMakeRect(0, 0, 200, 24))
		passbox.stringValue = "Enter password"
 		if let cred = challenge.proposedCredential {
			if cred.hasPassword { passbox.stringValue = cred.password! }
		}
		passbox.isEditable = true

		prompts.subviews = [userbox, passbox]

 		alert.accessoryView = prompts

		//alert.beginSheetModalForWindow(webView.window!, completionHandler:{(response: NSApplication.ModalResponse) -> Void in
		displayAlert(alert) { (response: NSApplication.ModalResponse) -> Void in
			if response == .alertFirstButtonReturn {
				completionHandler(.useCredential, URLCredential(
					user: userbox.stringValue,
					password: passbox.stringValue,
					persistence: .permanent
				))
			} else {
				// need to cancel request, else user can get locked into a modal prompt loop
				//completionHandler(.PerformDefaultHandling, nil)
				completionHandler(.rejectProtectionSpace, nil)
				webView.stopLoading()
			}
 		}
	}
}

// modules/WebKitPrivates/_WKDownloadDelegate.h
// https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/Cocoa/DownloadClient.mm
// https://github.com/WebKit/webkit/blob/master/Tools/TestWebKitAPI/Tests/WebKit2Cocoa/Download.mm
extension WebViewControllerOSX { // _WKDownloadDelegate
	override func _download(_ download: _WKDownload!, decideDestinationWithSuggestedFilename filename: String!, allowOverwrite: UnsafeMutablePointer<ObjCBool>) -> String! {
		warn(download.description)
		//pop open a save Panel to dump data into file
		let saveDialog = NSSavePanel()
		saveDialog.canCreateDirectories = true
		saveDialog.nameFieldStringValue = filename
		if let webview = download.originatingWebView, let window = webview.window {
			NSApplication.shared.requestUserAttention(.informationalRequest)
			saveDialog.beginSheetModal(for: window) { (choice: NSApplication.ModalResponse) -> Void in
				NSApp.stopModal(withCode: choice)
				return
			}
			if NSApp.runModal(for: window) != .abort { if let url = saveDialog.url { return url.path } }
		}
		download.cancel()
		return ""
	}
}

extension WebViewControllerOSX { // HTML5 fullscreen
	func _webViewFullscreenMayReturnToInline(_ webView: WKWebView) -> Bool {
		// https://developer.apple.com/reference/webkit/wkwebviewconfiguration/1614793-allowsinlinemediaplayback
		warn()
		return true
	}

	// https://developer.mozilla.org/en-US/docs/Web/API/Fullscreen_API
	//   https://github.com/WebKit/webkit/blob/fdbe0fbe284beb61d253ee00119346b5e3f41957/Source/WebKit2/Shared/WebPreferencesDefinitions.h#L142

	// https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/mac/WKFullScreenWindowController.mm
	//  https://github.com/WebKit/webkit/search?q=fullScreenWindowController
	// https://github.com/WebKit/webkit/blob/master/Source/WebCore/platform/mac/WebVideoFullscreenInterfaceMac.mm
	func _webViewDidEnterFullscreen(_ webView: WKWebView) {
		warn("JS <\(webView.urlstr)>: `<video>.requestFullscreen(); // begun`")
	}
	func _webViewDidExitFullscreen(_ webView: WKWebView) {
		warn("JS <\(webView.urlstr)>: `<video>.requestFullscreen(); // finished`")
	}
}

extension WebViewControllerOSX { // _WKFindDelegate
	func _webView(_ webView: WKWebView!, didCountMatches matches: UInt, forString string: String!) {
		warn()
	}
	func _webView(_ webView: WKWebView!, didFindMatches matches: UInt, forString string: String!, withMatchIndex matchIndex: Int) {
		warn()
	}
	func _webView(_ webView: WKWebView!, didFailToFindString string: String!) {
		warn()
	}
}

extension WebViewController { // _WKInputDelegate
	func _webView(_ webView: WKWebView!, didStart inputSession: _WKFormInputSession!) {
		//inputSession.valid .userObject .focusedElementInfo==[.Link,.Image]
		warn()
	}

	@objc func _webView(_ webView: WKWebView!, willSubmitFormValues values: [AnyHashable: Any]!, userObject: (NSSecureCoding & NSObjectProtocol)!, submissionHandler: (() -> Void)!) {
		warn(values.description)
		//userObject: https://github.com/WebKit/webkit/commit/c65916009f1e95f53f329ce3cfe69bf70616cc02#diff-776c38c9a3b2252729ea3ac028367308R1201
		submissionHandler()
	}
}

@available(OSX 10.12, *)
extension WebViewControllerOSX { // WKOpenPanel for <input> file uploading
	// https://bugs.webkit.org/show_bug.cgi?id=137759
	// https://github.com/WebKit/webkit/blob/4b7052ab44fa581810188638d1fdf074e7d754ca/Tools/MiniBrowser/mac/WK2BrowserWindowController.m#L451
	@objc func webView(_ webView: WKWebView!, runOpenPanelWithParameters parameters: WKOpenPanelParameters!, initiatedByFrame frame: WKFrameInfo!, completionHandler: (([NSURL]?) -> Void)!) {
		warn("<input> file upload panel opening!")
		//pop open a save Panel to dump data into file
		let openDialog = NSOpenPanel()
		openDialog.allowsMultipleSelection =  parameters.allowsMultipleSelection
		if let window = webview.window {
			NSApplication.shared.requestUserAttention(.informationalRequest)
			openDialog.beginSheetModal(for: window) { (choice: NSApplication.ModalResponse) -> Void in
				if choice == .OK {
					completionHandler(openDialog.urls as [NSURL]?)
				} else {
					completionHandler(nil)
				}
			}
		}
	}
}

@objc extension WebViewControllerOSX { // WKUIDelegatePrivate

	@available(OSX 10.13.4, *, iOS 11.3)
	@objc func _webView(_ webView: WKWebView!, requestGeolocationPermissionForFrame frame: WKFrameInfo!, decisionHandler: ((Bool) -> Void)!) {
		warn(webView.url?.absoluteString ?? "")

		//TODO: prompt for approval which could "unlock" the thunk that uiClient will fire after handler(). thunk actaully calls the C api to push approval
		// if unapproved, handle(false) & return now

		if let mpwv = webView as? MPWebView {
			Geolocator.shared.subscribeToLocationEvents(webview: mpwv)
			// this should warm up the locator
			// FIXME: do this with Async?
		}

		/*
		// so lets do some yucky hackery to polyfill+reload once for the life of the tab
		if let mpwv = webView as? MPWebView, mpwv.preinject("shim_html5_geolocation") {
			mpwv.subscribeTo("MacPinPollStates")
			mpwv.subscribeTo("getGeolocation")
			mpwv.subscribeTo("watchGeolocation")
			mpwv.subscribeTo("deactivateGeolocation")
			webView.reload() // hafta reload for the preinjection to happen
		}
		*/

		decisionHandler(true) // signal that we are done
	}

	//func _webView(_ webView: WKWebView!, editorStateDidChange editorState: [AnyHashable : Any]!)
	//func _webView(_ webView: WKWebView!, requestNotificationPermissionForSecurityOrigin securityOrigin: WKSecurityOrigin!, decisionHandler: ((Bool) -> Void)!)

	// handler for PDFViewer's Save-to-File button (blobbed PDFs)
	@objc func _webView(_ webView: WKWebView!, saveDataToFile data: Data!, suggestedFilename: String!, mimeType: String!, originatingURL url: URL!) {
		warn(url.description)
		//pop open a save Panel to dump data into file
		let saveDialog = NSSavePanel()
		saveDialog.canCreateDirectories = true
		saveDialog.nameFieldStringValue = suggestedFilename
		if let window = webview.window {
			NSApplication.shared.requestUserAttention(.informationalRequest)
			saveDialog.beginSheetModal(for: window) { (result: NSApplication.ModalResponse) -> Void in
				if let url = saveDialog.url, result == .OK {
					FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
				}
			}
		}
	}

	@available(OSX 10.13, *)
	@objc func _webView(_ webView: WKWebView!, requestUserMediaAuthorizationFor devices: _WKCaptureDevices, url: URL!, mainFrameURL: URL!, decisionHandler: ((Bool) -> Void)!) {
		warn(url.absoluteString)
		decisionHandler(true)
	}

	@available(OSX 10.12.3, *)
	@objc func _webView(_ webView: WKWebView!, checkUserMediaPermissionFor url: URL!, mainFrameURL: URL!, frameIdentifier: UInt, decisionHandler: ((String?, Bool) -> Void)!) {
		warn(url.absoluteString)
		//decisionHandler(url.absoluteString, true)
		decisionHandler("0x987654321", true)
	}

	// JS window.beforeunload() handler
	func _webView(_ webView: WKWebView!, runBeforeUnloadConfirmPanelWithMessage message: String!, initiatedByFrame frame: WKFrameInfo!, completionHandler: ((Bool) -> Void)!) {
		let alert = NSAlert()
		alert.messageText = webView.title ?? ""
		alert.addButton(withTitle: "Leave Page")
		alert.addButton(withTitle: "Stay on Page")
		alert.informativeText = "Are you sure you want to leave this page?" //message
		// Safari 9.1+, Chrome 51+, & Firefox 44+ do not allow JS to customize the msgTxt. Thanks scammers.
		alert.icon = NSApplication.shared.applicationIconImage
		displayAlert(alert) { (response: NSApplication.ModalResponse) -> Void in completionHandler(response == .alertFirstButtonReturn) }
 }

	func _webView(_ webView: WKWebView, printFrame: WKFrameInfo) {
		warn("JS: `window.print();`")
#if STP
		let printer = webView._printOperation(with: NSPrintInfo.shared)
		printer?.showsPrintPanel = true
		printer?.run()
#endif
	}

	//@objc func _webView(_ webView: WKWebView!, drawHeaderInRect rect: CGRect, forPageWithTitle title: String!, URL url: URL!) { warn(); }
	// webview._webViewHeaderHeight
	//@objc func _webView(_ webView: WKWebView!, drawFooterInRect rect: CGRect, forPageWithTitle title: String!, URL url: URL!) { warn(); }
	// webview._webViewFooterHeight

	@available(OSX 10.13, *, iOS 11.0)
	@objc func webView(_ webView: WebView!, dragDestinationActionMaskForDraggingInfo draggingInfo: NSDraggingInfo!) -> Int {
		warn()
		return Int(WKDragDestinationAction.any.rawValue) // accept the drag
		// .none .DHTML .edit .load
	}
	// @objc func _webView(_ webView: WKWebView!, getContextMenuFromProposedMenu menu: NSMenu!, forElement element: _WKContextMenuElementInfoQ, userInfo: Any!, completionHandler: ((NSMenu) -> Void)!) {}

}
