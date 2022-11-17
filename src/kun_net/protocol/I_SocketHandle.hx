package kun_net.protocol;

interface I_SocketHandle<DATA_T, MSG_T> {
	function onClose(_callbackFn:Void->Void = null):Void;
	function onData(_callbackFn:DATA_T->Void = null):Void;
	function onOpen(_callbackFn:Void->Void):Void;
	function onError(_callbackFn:Dynamic->Void):Void;
	function send(msg:Any):Void;
	function close():Void;
	function msgIn(packageData:MSG_T):Void;
}
