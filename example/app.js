Titanium.UI.setBackgroundColor('#000');
var tisip = require("com.crissmoldovan.tisip");

/**
 * Attach event listeners for registration, calls, messages and mwi (message waiting indicator) events.
 */
tisip.addEventListener('REGISTRATION.CONNECTING', function(event){
	console.log("TI got REGISTRATION.CONNECTING with args:");
	console.log(event);
	statusLabel.text = "connecting...";
	callButton.hide();
	textButton.hide();
});
tisip.addEventListener('REGISTRATION.DISCONNECTING', function(event){
	console.log("TI got REGISTRATION.DISCONNECTING with args:");
	console.log(event);
	callButton.hide();
	textButton.hide();
});
tisip.addEventListener('REGISTRATION.CONNECTED', function(event){
	console.log("TI got REGISTRATION.CONNECTED with args:");
	console.log(event);
	statusLabel.text = "connected";
	callButton.show();
	textButton.show();
});
tisip.addEventListener('REGISTRATION.DISCONNECTED', function(event){
	console.log("TI got REGISTRATION.DISCONNECTED with args:");
	console.log(event);
	statusLabel.text = "disconnected";
	callButton.hide();
	textButton.hide();
});
tisip.addEventListener('REGISTRATION.OFFLINE', function(event){
	console.log("TI got REGISTRATION.OFFLINE with args:");
	console.log(event);
	statusLabel.text = "---";
});
tisip.addEventListener('REGISTRATION.INVALID', function(event){
	console.log("TI got REGISTRATION.INVALID with args:");
	console.log(event);
	statusLabel.text = "---";
});
tisip.addEventListener('MWI', function(event){
	console.log("TI got MWI with args:");
	console.log(event);
});
tisip.addEventListener('MESSAGE.INCOMING', function(event){
	console.log("TI got MESSAGE.INCOMING with args:");
	console.log(event);
});
tisip.addEventListener('MESSAGE.STATUS', function(event){
	console.log("TI got MESSAGE.STATUS with args:");
	console.log(event);
});

tisip.addEventListener('CALL.INCOMING', function(event){
	console.log("TI got CALL.INCOMING with args:");
	console.log(event);
	activeCall = event.callId;
	callButton.hide();
	textButton.hide();
	answerCallButton.show();
	hangupCallButton.show();
});

tisip.addEventListener('CALL.READY', function(event){
	console.log("TI got CALL.READY with args:");
	console.log(event);
});

tisip.addEventListener('CALL.CALLING', function(event){
	console.log("TI got CALL.CALLING with args:");
	console.log(event);
	activeCall = event.callId;
	callButton.hide();
	textButton.hide();
});

tisip.addEventListener('CALL.CONNECTING', function(event){
	console.log("TI got CALL.CONNECTING with args:");
	console.log(event);
	activeCall = event.callId;
	hangupCallButton.show();
});

tisip.addEventListener('CALL.CONNECTED', function(event){
	console.log("TI got CALL.CONNECTED with args:");
	console.log(event);
	activeCall = event.callId;
	answerCallButton.hide();
	hangupCallButton.show();
});

tisip.addEventListener('CALL.DISCONNECTED', function(event){
	console.log("TI got CALL.DISCONNECTED with args:");
	console.log(event);
	callButton.show();
	textButton.show();
	answerCallButton.hide();
	hangupCallButton.hide();
	activeCall = null;
});

/** keep track of contectivity status **/
var connected = false;

/** 
 * the account id that is currently registered;
 * you can register multiple accounts
 */
var registeredAccount = null;
var activeCall = null;

var win = Titanium.UI.createWindow({  
    title:'Tab 1',
    backgroundColor:'#fff',
    layout: 'vertical'
});

var statusLabel = Ti.UI.createLabel({
	top: 30,
	text: '---',
	width: 'auto'
});

win.add(statusLabel);

var connectButton = Titanium.UI.createButton({
	title: 'Connect',
	textAlign:'center',
	width:Ti.UI.FILL
});

connectButton.addEventListener('click', function(){
	if (!connected){
		var accountId = tisip.register({
			account: "101",
			domain: "example.com",
			realm: "example.com",
			username: "101",
			password: "101"
		});
		
		if (accountId>=0){
			alert("registration OK");
			connected = true;
			registeredAccount = accountId;
			connectButton.title = 'Disconnect';
		}else{
			alert("registration failed");
			statusLabel.text = "---";
		}
	}else{
		var result = tisip.unregister(registeredAccount);

		if (result>=0){
			alert("unreg OK");
			connectButton.title = 'Connect';
			connected = false;
			registeredAccount = null;
			statusLabel.text = "---";
		}else{
			alert("unreg failed");
		}
	}
});

win.add(connectButton);

var callButton = Titanium.UI.createButton({
	title: 'Call',
	textAlign:'center',
	width:Ti.UI.FILL,
	visible: false
});

callButton.addEventListener('click', function(){
	if (connected){
		tisip.placeCall({
			accountId: registeredAccount, 
			uri: "sip:102@example.com:5060"
		});	
	}else{
		alert('cannot call as not connected');
	}
});

win.add(callButton);

var answerCallButton = Titanium.UI.createButton({
	title: 'Answer Call',
	textAlign:'center',
	width:Ti.UI.FILL,
	visible: false
});

answerCallButton.addEventListener('click', function(){
	if (connected && activeCall!=null){
		tisip.answerCall(activeCall);	
	}
});

win.add(answerCallButton);

var hangupCallButton = Titanium.UI.createButton({
	title: 'Hangup Call',
	textAlign:'center',
	width:Ti.UI.FILL,
	visible: false
});

hangupCallButton.addEventListener('click', function(){
	if (connected && activeCall!=null){
		tisip.hangUpCall(activeCall);	
	}
});

win.add(hangupCallButton);

var textButton = Titanium.UI.createButton({
	title: 'text',
	textAlign:'center',
	width:Ti.UI.FILL,
	visible: false
});

textButton.addEventListener('click', function(){
	if (connected){
		var date = new Date();
		tisip.sendText({
			accountId: registeredAccount,
			uri: "sip:102@example.com:5060",
			content: "test "+date.toISOString()
		});
	}else{
		alert('cannot text as not connected');
	}
});

win.add(textButton);


win.open();
