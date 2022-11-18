package kun_net.core;

import hx.ws.HttpHeader;
import hx.ws.OpCode;
import hx.ws.HttpRequest;
import hx.ws.HttpResponse;
import hx.ws.Log;
import hx.ws.State;
import hx.ws.WebSocketCommon;
import hx.ws.Types.MessageType;
import haxe.crypto.Base64;
import haxe.crypto.Sha1;
import haxe.io.Bytes;
import haxe.io.Error;

class WebSocketHandler extends WebSocketCommon {
	public static var MAX_WAIT_TIME:Int = 1000; // if no handshake has happened after this time (in seconds), we'll consider it dead and disconnect

	private var _creationTime:Float;

	var stream:hl.uv.Stream;

	public function new(socketHandleImpl:SocketHandleImpl, _stream:hl.uv.Stream) {
		super();
		_creationTime = Sys.time();
		id = socketHandleImpl.nickName;
		stream = _stream;
		// socketHandleImpl.onData(onmessage);
		isClient = false;
	}

	public function handle(packageData:Bytes) {
		if (this.state == State.Handshake && Sys.time() - _creationTime > (MAX_WAIT_TIME / 1000)) {
			Log.info('No handshake detected in ${MAX_WAIT_TIME}ms, closing connection', id);
			this.close();
			return;
		}
		processKun(packageData);
	}

	private override function handleData() {
        switch (state) {
            case State.Handshake:
                var httpRequest = recvHttpRequest();
                if (httpRequest == null) {
                    return;
                }

                handshake(httpRequest);
                handleData();
            case _:
                super.handleData();
        }
    }

    public function handshake(httpRequest:HttpRequest) {
		Log.info('uri: ${httpRequest.uri}');
        var httpResponse = new HttpResponse();

        httpResponse.headers.set(HttpHeader.SEC_WEBSOSCKET_VERSION, "13");
        if (httpRequest.method != "GET" || httpRequest.httpVersion != "HTTP/1.1") {
            httpResponse.code = 400;
            httpResponse.text = "Bad";
            httpResponse.headers.set(HttpHeader.CONNECTION, "close");
            httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Bad request');
        } else if (httpRequest.headers.get(HttpHeader.SEC_WEBSOSCKET_VERSION) != "13") {
            httpResponse.code = 426;
            httpResponse.text = "Upgrade";
            httpResponse.headers.set(HttpHeader.CONNECTION, "close");
            httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Unsupported websocket client version: ${httpRequest.headers.get(HttpHeader.SEC_WEBSOSCKET_VERSION)}, Only version 13 is supported.');
        } else if (httpRequest.headers.get(HttpHeader.UPGRADE) != "websocket") {
            httpResponse.code = 426;
            httpResponse.text = "Upgrade";
            httpResponse.headers.set(HttpHeader.CONNECTION, "close");
            httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Unsupported upgrade header: ${httpRequest.headers.get(HttpHeader.UPGRADE)}.');
        } else if (httpRequest.headers.get(HttpHeader.CONNECTION).indexOf("Upgrade") == -1) {
            httpResponse.code = 426;
            httpResponse.text = "Upgrade";
            httpResponse.headers.set(HttpHeader.CONNECTION, "close");
            httpResponse.headers.set(HttpHeader.X_WEBSOCKET_REJECT_REASON, 'Unsupported connection header: ${httpRequest.headers.get(HttpHeader.CONNECTION)}.');
        } else {
            Log.debug('Handshaking', id);
            var key = httpRequest.headers.get(HttpHeader.SEC_WEBSOCKET_KEY);
            var result = makeWSKeyResponse(key);
            Log.debug('Handshaking key - ${result}', id);

            httpResponse.code = 101;
            httpResponse.text = "Switching Protocols";
            httpResponse.headers.set(HttpHeader.UPGRADE, "websocket");
            httpResponse.headers.set(HttpHeader.CONNECTION, "Upgrade");
            httpResponse.headers.set(HttpHeader.SEC_WEBSOSCKET_ACCEPT, result);
        }

        sendHttpResponse(httpResponse);

        if (httpResponse.code == 101) {
            _onopenCalled = false;
            state = State.Head;
            Log.debug('Connected', id);
        } else {
            close();
        }
    }

	override public function close() {
		if (state != State.Closed) {
			try {
				Log.debug("Closed", id);
				sendFrame(Bytes.alloc(0), OpCode.Close);
				state = State.Closed;
				stream.close(onclose);
			} catch (e:Dynamic) {}
		}
	}

	override public function writeBytes(data:Bytes) {
		try {
			stream.write(data);
		} catch (e:Dynamic) {
			Log.debug(Std.string(e), id);
			if (onerror != null) {
				onerror(Std.string(e));
			}
		}
	}

	private function processKun(packageData:Bytes) {
		if (_onopenCalled == false) {
			_onopenCalled = true;
			if (onopen != null) {
				onopen();
			}
		}

		if (_lastError != null) {
			var error = _lastError;
			_lastError = null;
			if (onerror != null) {
				onerror(error);
			}
		}

		if (packageData == null) {
			Log.debug("socket disconnect! ", id);
			if (onclose != null) {
				onclose();
			}
			return;
		}

		Log.debug("Bytes read: " + packageData.length, id);
		_buffer.writeBytes(packageData);
		handleData();
	}

	override public function sendHttpRequest(httpRequest:HttpRequest) {
		var data = httpRequest.build();

		Log.data(data, id);

		try {
			stream.write(Bytes.ofString(data));
		} catch (e:Dynamic) {
			if (onerror != null) {
				onerror(Std.string(e));
			}
			close();
		}
	}

	override public function sendHttpResponse(httpResponse:HttpResponse) {
		var data = httpResponse.build();

		Log.data(data, id);

		stream.write(Bytes.ofString(data));
	}
}
