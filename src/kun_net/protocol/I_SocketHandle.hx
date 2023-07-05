package kun_net.protocol;

interface I_SocketHandle<ON_DATA_T, MSG_IN_T, SEND_T> {
	private function onClose(_callbackFn:Void->Void = null):Void;
	private function onData(_callbackFn:ON_DATA_T->Void = null):Void;
	private function onOpen(_callbackFn:Void->Void):Void;
	private function onError(_callbackFn:Dynamic->Void):Void;
	private function send(msg:SEND_T):Void;
	private function close(?callb:Null<() -> Void>):Void;
	private function msgIn(packageData:MSG_IN_T):Void;
	// private function getLock():RLock;
}
