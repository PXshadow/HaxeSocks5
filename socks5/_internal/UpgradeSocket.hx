package socks5._internal;
import haxe.io.Error;
import sys.net.Socket.SocketHandle;
import sys.net.Host;
import haxe.io.Bytes;
import haxe.io.BytesData;
#if cpp
import cpp.NativeSocket;
import cpp.NativeSsl;
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

private class SocketInput extends haxe.io.Input {
	private var socket:UpgradeSocket;

	public function new(s:UpgradeSocket) {
		this.socket = s;
	}

	public override function readByte() {
		return {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) NativeSsl.ssl_recv_char(@:privateAccess socket.ssl); #end
				0;
			}else{
				#if (cpp || neko) NativeSocket.socket_recv_char(@:privateAccess socket.__s); #end
				0;
			}
		};
	}

	public override function readBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
		var r:Int = 0;
		if (socket == null)
			throw "Invalid handle";
		try {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) r = NativeSsl.ssl_recv(@:privateAccess socket.ssl,buf.getData(),pos,len); #end
				#if (hl || hashlink) r = @:privateAccess socket.ssl.recv(buf,pos,len); #end
			}else{
				#if (cpp || neko) r = NativeSocket.socket_recv(@:privateAccess socket.__s,buf.getData(),pos,len); #end
				#if (hl || hashlink) r = socket_recv(@:privateAccess socket.__s, buf.getData().bytes, pos, len); #end
			}
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw Blocked;
			else
				throw Custom(e);
		}
		if (r == 0)
			throw new haxe.io.Eof();
		return r;
	}

	public override function close() {
		super.close();
		if (socket != null)
			socket.close();
	}
	#if (hl || hashlink)
	@:hlNative("std", "socket_recv") static function socket_recv(s:SocketHandle, bytes:hl.Bytes, pos:Int, len:Int):Int {
		return 0;
	}

	@:hlNative("std", "socket_recv_char") static function socket_recv_char(s:SocketHandle):Int {
		return 0;
	}
	#end
}

private class SocketOutput extends haxe.io.Output {
	private var socket:UpgradeSocket;
	public function new(s:UpgradeSocket) {
		this.socket = s;
	}

	public override function writeByte(c:Int) {
		try {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) NativeSsl.ssl_send_char(@:privateAccess socket.ssl, c); #end
			}else{
				#if (cpp || neko) NativeSocket.socket_send_char(@:privateAccess socket.__s,c); #end
			}
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw Blocked;
			else
				throw Custom(e);
		}
	}

	public override function writeBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
		return try {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) NativeSsl.ssl_send(@:privateAccess socket.ssl, buf.getData(), pos, len); #end
				#if (hl || hashlink)
				var r = @:privateAccess socket.ssl.send(buf, pos, len);
				if (r == -1)
					throw Blocked;
				else if (r < 0)
					throw new haxe.io.Eof();
				return r;
				#end
				//0;
			}else{
				#if (cpp || neko) NativeSocket.socket_send(@:privateAccess socket.__s, buf.getData(), pos, len); #end
				#if (hl || hashlink)
				if (pos < 0 || len < 0 || pos + len > buf.length)
					throw OutsideBounds;
				var n = socket_send(@:privateAccess socket.__s, buf.getData().bytes, pos, len);
				if (n < 0) {
					if (n == -1)
						throw Blocked;
					throw new haxe.io.Eof();
				}
				return n;
				#end
				//0;
			}
		}catch (e:Dynamic) {
			if (e == "Blocking")
				throw Blocked;
			else
				throw Custom(e);
		}
	}

	public override function close() {
		super.close();
		if (socket != null)
			socket.close();
	}
	#if (hl || hashlink)
	@:hlNative("std", "socket_send_char") static function socket_send_char(s:SocketHandle, c:Int):Int {
		return 0;
	}

	@:hlNative("std", "socket_send") static function socket_send(s:SocketHandle, bytes:hl.Bytes, pos:Int, len:Int):Int {
		return 0;
	}
	#end
}
/**
    std/eval/_std/sys/ssl/Socket.hx
    std/cpp/_std/sys/ssl/Socket.hx
    std/neko/_std/sys/ssl/Socket.hx
    std/hl/_std/sys/ssl/Socket.hx

    std/java/_std/sys/ssl/Socket.hx
    std/jvm/_std/sys/ssl/Socket.hx

    std/cs/_std/sys/ssl/Socket.hx

    std/lua/_std/sys/ssl/Socket.hx
    std/python/_std/sys/ssl/Socket.hx
**/
class UpgradeSocket extends sys.ssl.Socket
{
	public var upgraded:Bool = false;
	#if !neko var ctx:Dynamic; #end
	override function init() {
		super.init();
		#if !neko ctx = conf; #end
		input = new SocketInput(this);
		output = new SocketOutput(this);
		verifyCert = false;
	}
    public function upgrade()
    {
		upgraded = true;
		handshakeDone = false;
		if (hostname == null) throw "hostname not set";
		trace('host $hostname');
		#if (neko || cpp) NativeSsl.ssl_set_hostname(ssl, #if neko untyped hostname.__s #else hostname #end); #end
		#if (hl || hashlink) ssl.setHostname(@:privateAccess hostname.toUtf8()); #end
		//setBlocking(true);
		handshake();
	}
	public function downgrade()
	{
		
	}
	override function handshake() {
		trace("handshake");
		super.handshake();
	}
	override function connect(host:Host, port:Int) {
		try {
			ctx = buildSSLConfig(false);
			handshakeDone = true; //turns into upgrade
			#if (neko || cpp)
			ssl = NativeSsl.ssl_new(ctx);
			NativeSsl.ssl_set_socket(ssl, __s);
			NativeSocket.socket_connect(__s, host.ip, port);
			} catch (s:String) {
				if (s == "std@socket_connect")
					throw "Failed to connect on " + host.host + ":" + port;
				else if (s == "Blocking") {
					// Do nothing, this is not a real error, it simply indicates
					// that a non-blocking connect is in progress
				}else
					Lib.rethrow(s);
			} catch (e:Dynamic) {
				Lib.rethrow(e);
			}
			#elseif hl
			}
			#end
	}
	#if neko public function buildSSLConfig(server:Bool) {return buildSSLContext(server);}#end
	#if (hl || hashlink) public function buildSSLConfig(server:Bool) {return buildConfig(server);}#end
	#if !hl
	override function read():String {
		#if neko var b:String; #end
		#if cpp var b:BytesData; #end
		if (upgraded)
		{
			handshake();
			#if (cpp || neko) b = NativeSsl.ssl_read(ssl); #end
		}else{
			#if (cpp || neko) b = NativeSocket.socket_read(__s); #end
		}
		if (b == null)
			return "";
		#if neko return new String(cast b); #end
		#if cpp return haxe.io.Bytes.ofData(b).toString(); #end
		return "";
	}
	public override function write(content:String):Void {
		if (upgraded)
		{
		   handshake();
		   NativeSsl.ssl_write(ssl, #if neko untyped content.__s #elseif (cpp || hl || eval) haxe.io.Bytes.ofString(content).getData() #end);
		}else{
		   NativeSocket.socket_write(__s, #if neko untyped content.__s #else haxe.io.Bytes.ofString(content).getData() #end);
		}
	}
	#end
	override function close() {
		if (upgraded)
		{
			#if (neko || cpp)
			if (ssl != null)
				NativeSsl.ssl_close(ssl);
			if (ctx != null)
				NativeSsl.conf_close(ctx);
			NativeSocket.socket_close(__s);
			var input:SocketInput = cast input;
			var output:SocketOutput = cast output;
			@:privateAccess input.socket = output.socket = null;
			input.close();
			output.close();
			#end
		}else{
			#if (neko || cpp)
			NativeSocket.socket_close(__s);
			#elseif hl
			if (ssl != null)
				ssl.close();
			if (conf != null)
				conf.close();
			if (altSNIContexts != null)
				sniCallback = null;
			sys.net.Socket.socket_close(__s);
			var input:SocketInput = cast input;
			var output:SocketOutput = cast output;
			@:privateAccess input.socket = output.socket = null;
			input.close();
			output.close();
			#end
		}
	}
}
#if neko
private class NativeSsl
{
    public static var ssl_new = neko.Lib.loadLazy("ssl", "ssl_new", 1);
	public static var ssl_close = neko.Lib.loadLazy("ssl", "ssl_close", 1);
	public static var ssl_handshake = neko.Lib.loadLazy("ssl", "ssl_handshake", 1);
	public static var ssl_set_socket = neko.Lib.loadLazy("ssl", "ssl_set_socket", 2);
	public static var ssl_set_hostname = neko.Lib.loadLazy("ssl", "ssl_set_hostname", 2);
	public static var ssl_get_peer_certificate = neko.Lib.loadLazy("ssl", "ssl_get_peer_certificate", 1);

	public static var ssl_read = neko.Lib.loadLazy("ssl", "ssl_read", 1);
	public static var ssl_write = neko.Lib.loadLazy("ssl", "ssl_write", 2);

	public static var conf_new = neko.Lib.loadLazy("ssl", "conf_new", 1);
	public static var conf_close = neko.Lib.loadLazy("ssl", "conf_close", 1);
	public static var conf_set_ca = neko.Lib.loadLazy("ssl", "conf_set_ca", 2);
	public static var conf_set_verify = neko.Lib.loadLazy("ssl", "conf_set_verify", 2);
	public static var conf_set_cert = neko.Lib.loadLazy("ssl", "conf_set_cert", 3);
    public static var conf_set_servername_callback = neko.Lib.loadLazy("ssl", "conf_set_servername_callback", 2);
    
    public static var ssl_recv = neko.Lib.loadLazy("ssl", "ssl_recv", 4);
    public static var ssl_recv_char = neko.Lib.loadLazy("ssl", "ssl_recv_char", 1);
    
    public static var ssl_send_char = neko.Lib.loadLazy("ssl", "ssl_send_char", 2);
	public static var ssl_send = neko.Lib.loadLazy("ssl", "ssl_send", 4);
}
private class NativeSocket
{
    public static var socket_new = neko.Lib.load("std", "socket_new", 1);
	public static var socket_close = neko.Lib.load("std", "socket_close", 1);
	public static var socket_connect = neko.Lib.load("std", "socket_connect", 3);
	public static var socket_bind = neko.Lib.load("std", "socket_bind", 3);
    public static var socket_accept = neko.Lib.load("std", "socket_accept", 1);

	public static var socket_send_char = neko.Lib.load("std", "socket_send_char", 2);
	public static var socket_send = neko.Lib.load("std", "socket_send", 4);

    public static var socket_read = neko.Lib.load("std", "socket_read", 1);
    public static var socket_write = neko.Lib.load("std", "socket_write", 2);
    
    public static var socket_recv = neko.Lib.load("std", "socket_recv", 4);
	public static var socket_recv_char = neko.Lib.load("std", "socket_recv_char", 1);
}
#end