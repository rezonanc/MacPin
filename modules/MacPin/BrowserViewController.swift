import JavaScriptCore
import AppKit

// https://electronjs.org/docs/api/browser-window
@objc protocol BrowserViewControllerJS: JSExport { // '$.browser' in app.js
	init?(object: JSValue)
	var defaultUserAgent: String? { get set } // full UA used for any new tab without explicit UA specified
	var isFullscreen: Bool { get set }
	var isToolbarShown: Bool { get set }
	var tabSelected: AnyObject? { get set }
    //var matchedAddressOptions: [String:String] { get set }
	@objc(_tabs) var tabs: [MPWebView] { get set }
	// https://bugs.swift.org/browse/SR-6476 support $.browser[N] for accessing tabs?
	func close()
	func switchToNextTab()
	func switchToPreviousTab()
	func closeTab(_ tab: AnyObject?)
	func newTabPrompt()
	func newIsolatedTabPrompt()
	func newPrivateTabPrompt()
	func focusOnBrowser()
	func unhideApp()
	func bounceDock()
	func addShortcut(_ title: String, _ obj: AnyObject?)
	func extend(_ mountObj: JSValue)
	func unextend(_ mountObj: JSValue)
}

@objc protocol BrowserViewController: BrowserViewControllerJS {
	var view: View { get }
	var title: String? { get set }
#if os(OSX)
	func present() -> WindowController
	var tabMenu: NSMenu { get } // FIXME: cross-plat menuitem enumerable
	var shortcutsMenu: NSMenu { get } // FIXME: cross-plat menuitem enumerable
#endif
	var childViewControllers: [ViewController] { get set }
	static func exportSelf(_ mountObj: JSValue, _ name: String)
}
