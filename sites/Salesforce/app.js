/*eslint-env applescript*/
/*eslint-env es6*/
/*eslint-env builtins*/
/*eslint eqeqeq:0, quotes:0, space-infix-ops:0, curly:0*/
"use strict";

var salesforceTab, salesforce = {
	url: 'https://login.salesforce.com/',
	subscribeTo: ['receivedHTML5DesktopNotification', "MacPinPollStates"],
	postinject: ['shim_html5_notifications'],
	style: ['psa']
};
$.browser.tabSelected = salesforceTab = new $.WebView(salesforce);

var delegate = {}; // our delegate to receive events from the webview app

delegate.receivedHTML5DesktopNotification = function(tab, note) {
	console.log(Date() + ' [posted HTML5 notification] ' + note);
	$.app.postHTML5Notification(note);
};

delegate.handleClickedNotification = function(title, subtitle, msg, id) {
	console.log("JS: opening notification for: "+ [title, subtitle, msg, id]);
	$.browser.tabSelected = salesforceTab;
	//salesforceTab.evalJS();
	return true;
};

delegate.launchURL = function(url) {
	console.log("app.js: launching " + url);
	var comps = url.split(':'),
		scheme = comps.shift(),
		addr = comps.shift();
	switch (scheme) {
		case "salesforce": //FIXME: support search for find users, channels
			break;
		default:
			$.browser.tabSelected = new $.WebView({url: url});
	}
};

delegate.decideNavigationForURL = function(url) {
	var comps = url.split(':'),
		scheme = comps.shift(),
		addr = comps.shift(),
		subpath = addr.split('/')[1];
	switch (scheme) {
		case "http":
		case "https":
			if (
				 (~addr.indexOf(".salesforce.com/")) &&
				(~addr.indexOf("//salesforce.com/"))
			) {
				$.app.openURL(url); //pop all external links to system browser
				console.log("opened "+url+" externally!");
				return true; //tell webkit to do nothing
			}
		case "about":
		case "file":
		default:
			return false;
	}
};

$.app.loadAppScript(`file://${$.app.resourcePath}/enDarken.js`);
$.browser.addShortcut('Dark Mode', ['enDarken']);

delegate.AppFinishedLaunching = function() {
	$.browser.addShortcut('Salesforce', salesforce);
};

delegate; //return this to macpin
