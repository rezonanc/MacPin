/// MacPin WebViewControllerOSX
///
/// WebViewController subclass for Mac OSX

import WebKit
import WebKitPrivates

@objc class WebViewControllerOSX: WebViewController, NSTextFinderBarContainer {
	let textFinder = NSTextFinder()
	var findBarView: NSView? {
		willSet { if findBarView != nil { _findBarVisible = false } }
		didSet { if findBarView != nil { _findBarVisible = true } }
	}
	fileprivate var _findBarVisible = false
	var isFindBarVisible: Bool {
		@objc(isFindBarVisible) get { return _findBarVisible }
		//set(vis) {
		@objc(setFindBarVisible:) set (vis) {
			_findBarVisible = vis
			if let findview = findBarView {
				vis ? view.addSubview(findview) : findview.removeFromSuperview()
			}
			layout()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		//view.wantsLayer = true //use CALayer to coalesce views
		//^ default=true:  https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/API/mac/WKView.mm#L3641
		view.autoresizesSubviews = true
		view.autoresizingMask = [.width, .height]
		webview.autoresizingMask = [.width, .height]
#if STP
		// scale-to-fit https://github.com/WebKit/webkit/commit/b40b702baeb28a497d29d814332fbb12a2e25d03
		webview._layoutMode = .dynamicSizeComputedFromViewScale
#endif

		bind(NSBindingName.title, to: webview, withKeyPath: #keyPath(MPWebView.title), options: nil)
		//backMenu.delegate = self
		//forwardMenu.delegate = self

		//webview._editable = true //makes about:blank editable by default
		textFinder.client = webview
		textFinder.findBarContainer = self
		textFinder.isIncrementalSearchingEnabled = true
		textFinder.incrementalSearchingShouldDimContentView = true
		// FIXME: webview doesn't auto-scroll to found matches
		//  https://github.com/WebKit/webkit/blob/112c663463807e8676765cb7a006d415c372f447/Source/WebKit2/UIProcess/mac/WKTextFinderClient.mm#L39
		// MiniBrowser: https://github.com/WebKit/webkit/commit/67ec9eb4a3e9f04ababc7ea6c0e5f9b5bf69ca1c
	}

	func contentView() -> NSView? { return webview }

	override func performTextFinderAction(_ sender: Any?) {
		if let control = sender as? NSMenuItem, let action = NSTextFinder.Action(rawValue: control.tag) {
			textFinder.performAction(action)
		}
	}

	override func viewWillAppear() { // window popping up with this tab already selected & showing
		layout()
		super.viewWillAppear() // or tab switching into view as current selection
	}

	override func viewDidAppear() { // window now loaded and showing view
		super.viewDidAppear()
		//view.autoresizesSubviews = false
		//view.translatesAutoresizingMaskIntoConstraints = false
		if let window = view.window {
			//window.backgroundColor = webview.transparent ? NSColor.clearColor() : NSColor.whiteColor()
			window.backgroundColor = window.backgroundColor.withAlphaComponent(webview.transparent ? 0 : 1) //clearColor | fooColor
			window.isOpaque = !webview.transparent
			window.hasShadow = !webview.transparent
			window.invalidateShadow()
			window.toolbar?.showsBaselineSeparator = window.titlebarAppearsTransparent ? false : !webview.transparent
		}
	}

	override func viewWillDisappear() {
		warn()
		super.viewWillDisappear()
	}

	override func viewDidDisappear() {
		warn()
		super.viewDidDisappear()
	}

	func findBarViewDidChangeHeight() { layout() }

	func layout() {
		warn()
		if let find = findBarView, _findBarVisible {
			find.frame = CGRect(x: view.bounds.origin.x,
				y: view.bounds.origin.y + view.bounds.size.height - find.frame.size.height,
				width: view.bounds.size.width, height: find.frame.size.height)
			webview.frame = CGRect(x: view.bounds.origin.x, y: view.bounds.origin.y, width: view.bounds.size.width,
				height: view.bounds.size.height - find.frame.size.height)
		} else {
			webview.frame = view.bounds
		}
	}

	override func viewWillLayout() {
		//webview.resizeSubviewsWithOldSize(CGSizeZero)
		if webview != nil && view.window != nil { // vc's still in hierarchy can be asked to layout after view is deinit'd
			webview._inspectorAttachmentView = webview
			// BUG: sometimes get SIGSEGVs for this when JS is adding the viewcontroller....defer this to another delegate method?
		}
		super.viewWillLayout()
	}

	override func updateViewConstraints() {
#if WK2LOG
		warn("\(view.frame)")
#endif
		//super.updateViewContraints()
		view.updateConstraints()
		//view.removeConstraints(view.constraints)
	}

	deinit {
		//warn()
		textFinder.client = nil
		webview._inspectorAttachmentView = nil
		unbind(NSBindingName.title)
		Geolocator.shared.unsubscribeFromLocationEvents(webview: webview)
		// super.deinit is implicit here
	}

	override func cancelOperation(_ sender: Any?) { webview.stopLoading(sender) } // NSResponder: make Esc key stop page load
}

extension WebViewControllerOSX: NSMenuDelegate {
	func menuNeedsUpdate(_ menu: NSMenu) {
		//if menu.tag == 1 //backlist
		/*
		for histItem in webview.backForwardList.backList {
			let mi = NSMenuItem(title:(histItem.title ?? histItem.URL.absoluteString), action:Selector("gotoHistoryMenuURL:"), keyEquivalent:"" )
			mi.representedObject = histItem.URL
			mi.target = self
		}
		*/
	}
}

extension WebViewControllerOSX { // AppGUI funcs

	override func dismiss() {
		warn()
		webview._inspectorAttachmentView = nil
		textFinder.client = nil
		//webview.iconClient = nil
		//view?.removeFromSuperviewWithoutNeedingDisplay()
		super.dismiss()
	}

	@objc func toggleTransparency() { webview.transparent = !webview.transparent; viewDidAppear() }  // WKPageForceRepaint(webview.topFrame?.pageRef, 0, didForceRepaint);

#if STP
	@objc func zoomIn() { zoom(0.2) }
	@objc func zoomOut() { zoom(-0.2) }
	func zoom(_ factor: Double) {
		// https://github.com/WebKit/webkit/commit/1fe5bc35da4a688b9628e2e0b0c013fd0d44b9d5
		//webview.magnification -= factor
		textZoom(factor)
		return

		/*
		let oldScale = webview._viewScale
		let scale = oldScale + CGFloat(factor) // * page/magnification scale
		guard let window = view.window else {return}
		let oldFrame = window.frame
		//let oldFrame = view.frame
		let newFrameSize = NSMakeSize(oldFrame.size.width * (scale / oldScale), oldFrame.size.height * (scale / oldScale));
		window.setFrame(NSMakeRect(oldFrame.origin.x, oldFrame.origin.y - (newFrameSize.height - oldFrame.size.height), newFrameSize.width, newFrameSize.height), display: true)
		//view.frame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y - (newFrameSize.height - oldFrame.size.height), newFrameSize.width, newFrameSize.height)
		webview._viewScale = scale
		*/
	}
	func textZoomIn() { textZoom(0.2) }
	func textZoomOut() { textZoom(-0.2) }
	func textZoom(_ factor: Double) {
		webview._textZoomFactor += factor
	}
#else
	@objc func zoomIn() { webview.magnification += 0.2 } // user-adjustable "page" scale
	@objc func zoomOut() { webview.magnification -= 0.2 }
#endif
	@objc func zoomText() {
		webview._textZoomFactor = webview._textZoomFactor
		webview._pageZoomFactor = webview._pageZoomFactor
		webview._layoutMode = .dynamicSizeComputedFromViewScale
	}

	//@objc func print(_ sender: AnyObject?) { warn(""); webview.print(sender) }

	@objc func highlightConstraints() { view.window?.visualizeConstraints(view.constraints) }

	@objc func replaceContentView() { view.window?.contentView = view }

	@objc func shareButtonClicked(_ sender: AnyObject?) {
		if let btn = sender as? NSView {
			if let url = webview.url {
				let sharer = NSSharingServicePicker(items: [url])
				sharer.delegate = self
				sharer.show(relativeTo: btn.bounds, of: btn, preferredEdge: NSRectEdge.minY)
				//sharer.style = 1 // https://github.com/iljaiwas/NSSharingPickerTest/pull/1
			}
		}
	}

	@available(OSX 10.13, *, iOS 11)
	//#STP_21
	@objc func snapshotButtonClicked(_ sender: AnyObject?) {
		warn()
		guard let btn = sender as? NSView else { return }
		guard let thumb = _WKThumbnailView( // make a custom webview.thumbnail
			frame: CGRect(origin: CGPoint(x: 0, y: 0), size: webview.bounds.size.applying(CGAffineTransform(scaleX: 0.15, y: 0.15))),
			from: webview as WKWebView
		) else { return }

		var poprect = btn.bounds
		let snap = NSViewController()
		snap.view = thumb
		poprect.size.height -= snap.view.frame.height + 12 // make room at the top to stuff the popover
		presentViewController(snap, asPopoverRelativeTo: poprect, of: btn, preferredEdge: NSRectEdge.maxY, behavior: NSPopover.Behavior.transient)
	}

	func displayAlert(_ alert: NSAlert, _ completionHandler: @escaping (NSApplication.ModalResponse) -> Void) {
	/* FIXME BIG TIME
		make JS's modal alerts dismissable on tab change, like Safari does
		see: https://developers.google.com/web/updates/2017/03/dialogs-policy

		also rate-limit modals and nop them if limit exceeded
	*/
		if let window = view.window {
			alert.beginSheetModal(for: window, completionHandler: completionHandler)
		} else {
			completionHandler(alert.runModal())
		}
	}

	func popupMenu(_ items: [String: String]) { // trigger a menu @ OSX right-click & iOS longPress point
		let _ = NSMenu(title:"popup")
		// items: [itemTitle:String eventName:String], when clicked, fire event in jsdelegate?
		//menu.popUpMenu(menu.itemArray.first, atLocation: NSPointFromCGPoint(CGPointMake(0,0)), inView: self.view)
	}

/*
	func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
		switch (anItem.action().description) {
			case "performTextFinderAction:":
				if let action = NSTextFinderAction(rawValue: anItem.tag()) where textFinder.validateAction(action) { return true }
			default:
				break
		}
		return false
		//return webview.validateUserInterfaceItem(anItem)
	}
*/

	// https://github.com/WebKit/webkit/commit/7142fb3b53b77c1f4881f2c7b5fa2a61794cc2e0#diff-da59bd1d4a25653a6963b1d22bbc088f
	@objc func showHideWebInspector(_ sender: AnyObject?) {
		let inspectorRef = WKPageGetInspector(webview._pageRefForTransitionToWKWebView)
		if WKInspectorIsVisible(inspectorRef) {
			DispatchQueue.main.async() { WKInspectorHide(inspectorRef) }
			webview.window?.makeFirstResponder(webview)
		} else {
			DispatchQueue.main.async() { WKInspectorShow(inspectorRef) }
		}
	}
}

extension WebViewControllerOSX: NSSharingServicePickerDelegate { }

/*
extension WebViewControllerOSX: NSMenuDelegate {
	func menuNeedsUpdate(menu: NSMenu) {
		//if menu.tag == 1 //backlist
		for histItem in webview.backForwardList.backList {
			if let histItem = histItem as? WKBackForwardListItem {
				let mi = NSMenuItem(title:(histItem.title ?? histItem.URL.absoluteString!), action:Selector("gotoHistoryMenuURL:"), keyEquivalent:"" )
				mi.representedObject = histItem.URL
				mi.target = self
			}
		}
	}
}
*/
