package socks5;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Bytes;
import sys.net.Host;

class Http extends haxe.Http
{
    public static var PROXY:{host:String, port:Int, auth:{user:String, pass:String}} = null;
    public function new(url:String)
    {
        super(url);
    }
    public static function requestUrl(url:String):String {
		var h = new Http(url);
		var r = null;
		h.onData = function(d) {
			r = d;
		}
		h.onError = function(e) {
			trace('e $e');
		}
		h.request(false);
		return r;
    }
    /*override function customRequest(post:Bool, api:Output, ?sock:sys.net.Socket, ?method:String) {
        if (PROXY != null) Socket.PROXY = PROXY;
        sock = new Socket();
        super.customRequest(post, api, sock, method);
    }*/
    override public function customRequest(post:Bool, api:haxe.io.Output, ?sock:sys.net.Socket, ?method:String) {
        //proxy
        if (PROXY != null) Socket.PROXY = PROXY;
        var sock = new Socket();
        //main
		this.responseAsString = null;
		this.responseBytes = null;
		var url_regexp = ~/^(https?:\/\/)?([a-zA-Z\.0-9_-]+)(:[0-9]+)?(.*)$/;
		if (!url_regexp.match(url)) {
			onError("Invalid URL");
			return;
		}
		var secure = (url_regexp.matched(1) == "https://");
        sock.setTimeout(cnxTimeout);
		var host = url_regexp.matched(2);
		var portString = url_regexp.matched(3);
        var request = url_regexp.matched(4);
        sock.secure = secure;
		@:privateAccess sock.hostname = new Host(host).toString();
		// ensure path begins with a forward slash
		// this is required by original URL specifications and many servers have issues if it's not supplied
		// see https://stackoverflow.com/questions/1617058/ok-to-skip-slash-before-query-string
		if (request.charAt(0) != "/") {
			request = "/" + request;
		}
		var port = if (portString == null || portString == "") secure ? 443 : 80 else Std.parseInt(portString.substr(1, portString.length - 1));

		var multipart = (file != null);
		var boundary = null;
		var uri = null;
		if (multipart) {
			post = true;
			boundary = Std.string(Std.random(1000))
				+ Std.string(Std.random(1000))
				+ Std.string(Std.random(1000))
				+ Std.string(Std.random(1000));
			while (boundary.length < 38)
				boundary = "-" + boundary;
			var b = new StringBuf();
			for (p in params) {
				b.add("--");
				b.add(boundary);
				b.add("\r\n");
				b.add('Content-Disposition: form-data; name="');
				b.add(p.name);
				b.add('"');
				b.add("\r\n");
				b.add("\r\n");
				b.add(p.value);
				b.add("\r\n");
			}
			b.add("--");
			b.add(boundary);
			b.add("\r\n");
			b.add('Content-Disposition: form-data; name="');
			b.add(file.param);
			b.add('"; filename="');
			b.add(file.filename);
			b.add('"');
			b.add("\r\n");
			b.add("Content-Type: " + file.mimeType + "\r\n" + "\r\n");
			uri = b.toString();
		} else {
			for (p in params) {
				if (uri == null)
					uri = "";
				else
					uri += "&";
				uri += StringTools.urlEncode(p.name) + "=" + StringTools.urlEncode('${p.value}');
			}
		}

		var b = new BytesOutput();
		if (method != null) {
			b.writeString(method);
			b.writeString(" ");
		} else if (post)
			b.writeString("POST ");
		else
			b.writeString("GET ");

		if (Http.PROXY != null) {
			b.writeString("http://");
			b.writeString(host);
			if (port != 80) {
				b.writeString(":");
				b.writeString('$port');
			}
		}
		b.writeString(request);

		if (!post && uri != null) {
			if (request.indexOf("?", 0) >= 0)
				b.writeString("&");
			else
				b.writeString("?");
			b.writeString(uri);
		}
		b.writeString(" HTTP/1.1\r\nHost: " + host + "\r\n");
		if (postData != null) {
			postBytes = Bytes.ofString(postData);
			postData = null;
		}
		if (postBytes != null)
			b.writeString("Content-Length: " + postBytes.length + "\r\n");
		else if (post && uri != null) {
			if (multipart || !Lambda.exists(headers, function(h) return h.name == "Content-Type")) {
				b.writeString("Content-Type: ");
				if (multipart) {
					b.writeString("multipart/form-data");
					b.writeString("; boundary=");
					b.writeString(boundary);
				} else
					b.writeString("application/x-www-form-urlencoded");
				b.writeString("\r\n");
			}
			if (multipart)
				b.writeString("Content-Length: " + (uri.length + file.size + boundary.length + 6) + "\r\n");
			else
				b.writeString("Content-Length: " + uri.length + "\r\n");
		}
		b.writeString("Connection: close\r\n");
		for (h in headers) {
			b.writeString(h.name);
			b.writeString(": ");
			b.writeString(h.value);
			b.writeString("\r\n");
		}
		b.writeString("\r\n");
		if (postBytes != null)
			b.writeFullBytes(postBytes, 0, postBytes.length);
		else if (post && uri != null)
			b.writeString(uri);
		try {
			if (Http.PROXY != null)
				sock.connect(new Host(Http.PROXY.host), Http.PROXY.port);
			else
                sock.connect(new Host(host), port);
            trace("write body");
			if (multipart)
				writeBody(b, file.io, file.size, boundary, sock)
			else
                writeBody(b, null, 0, null, sock);
            trace("write body finished");
            readHttpResponse(api, sock);
            trace("read finished");
			sock.close();
		} catch (e:Dynamic) {
			try
				sock.close()
			catch (e:Dynamic) {};
			onError(Std.string(e));
		}
	}
	override function writeBody(body:Null<BytesOutput>, fileInput:Null<Input>, fileSize:Int, boundary:Null<String>, sock:sys.net.Socket) {
		trace("body " + body.getBytes().toString());
		super.writeBody(body, fileInput, fileSize, boundary, sock);
	}
}