package socks5._internal;

/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
import haxe.io.BytesData;
#if cpp
import cpp.NativeSsl;
import cpp.NativeSocket;
#end
 import sys.ssl.Certificate;
 #if (hl || hashlink)
 import sys.ssl.Context;
 import sys.ssl.Context.Config;
 #end
 import sys.ssl.Key;
 //import sys.net.Socket.SocketHandle;
 private typedef SocketHandle = Dynamic;
 private typedef CTX = Dynamic;
 private typedef SSL = Dynamic;
 
 private class SocketInput extends haxe.io.Input {
    private var __s:Socket;
    //private var __s:Dynamic;
     public function new(s:Socket) {
         this.__s = s;
     }
 
     public override function readByte() {
         return {
            if (__s.secureBool)
			{
                __s.handshake();
                #if (hl || hashlink)
                @:privateAccess __s.ssl.recvChar();
                #else
                NativeSsl.ssl_recv_char(@:privateAccess __s.ssl);
                #end
			}else{
                #if (hl || hashlink)
                @:privateAccess __s.__s.recvChar();
                #else
                NativeSocket.socket_recv_char(@:privateAccess __s.__s);
                #end
			}
         /*} catch (e:Dynamic) {
             if (e == "Blocking")
                 throw haxe.io.Error.Blocked;
             else if (__s == null)
                 throw haxe.io.Error.Custom(e);
             else
                 throw new haxe.io.Eof();
         }*/
        }
     }
 
     public override function readBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
         var r:Int;
         if (__s == null)
             throw "Invalid handle";
         try {
            if (__s.secureBool)
			{
                __s.handshake();
                #if (hl || hashlink)
                r = @:privateAccess __s.ssl.recv(buf, pos, len);
                #else
                r = NativeSsl.ssl_recv(@:privateAccess __s.ssl, buf.getData(), pos, len);
                #end
			}else{
                //r = 1;
                #if (hl || hashlink)
                r = @:privateAccess __s.__s.recv(buf, pos, len);
                #else
                r = NativeSocket.socket_recv(@:privateAccess __s.__s,buf.getData(),pos,len);
                #end
			}
         } catch (e:Dynamic) {
             if (e == "Blocking")
                 throw haxe.io.Error.Blocked;
             else
                 throw haxe.io.Error.Custom(e);
         }
         if (r == 0)
             throw new haxe.io.Eof();
         return r;
     }
 
     public override function close() {
         super.close();
         if (__s != null)
             __s.close();
     }

 }
 
 private class SocketOutput extends haxe.io.Output {
     private var __s:Socket;
     //private var __s:Dynamic;
 
     public function new(s:Socket) {
         this.__s = s;
     }
 
     public override function writeByte(c:Int) {
         try {
            if (__s.secureBool)
			{
                __s.handshake();
                #if (hl || hashlink)
                @:privateAccess var r = @:privateAccess __s.ssl.sendChar(c);
                #else
                NativeSsl.ssl_send_char(@:privateAccess __s.ssl, c);
                #end
			}else{
                #if (hl || hashlink)
                @:privateAccess var r = @:privateAccess __s.__s.sendChar(c);
                #else
                NativeSocket.socket_send_char(@:privateAccess __s.__s,c);
                #end
			}
         } catch (e:Dynamic) {
             if (e == "Blocking")
                 throw haxe.io.Error.Blocked;
             else
                 throw haxe.io.Error.Custom(e);
         }
     }
 
     public override function writeBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
         return try {
            if (__s.secureBool)
			{
                __s.handshake();
                #if (hl || hashlink)
                @:privateAccess __s.ssl.send(buf, pos, len);
                #else
                NativeSsl.ssl_send(@:privateAccess __s.ssl, buf.getData(), pos, len);
                #end
			}else{
                //return 1;
                #if (hl || hashlink)
                @:privateAccess __s.__s.send(buf, pos, len);
                #else
                NativeSocket.socket_send(@:privateAccess __s.__s, buf.getData(), pos, len);
                #end
			}
         } catch (e:Dynamic) {
             if (e == "Blocking")
                 throw haxe.io.Error.Blocked;
             else
                 throw haxe.io.Error.Custom(e);
         }
     }
 
     public override function close() {
         super.close();
         if (__s != null)
             __s.close();
     }
 }
 
 class Socket extends sys.net.Socket {
     public static var DEFAULT_VERIFY_CERT:Null<Bool> = true;
 
     public static var DEFAULT_CA:Null<Certificate>;
     
     #if (cpp || neko)
     private var ssl:SSL;
     private var ctx:CTX;   
     #end
     #if (hl || hashlink)
     private var ssl:Context;
     private var ctx:Config;
     #end
 
     public var verifyCert:Int;
 
     private var caCert:Null<Certificate>;
 
     private var ownCert:Null<Certificate>;
     private var ownKey:Null<Key>;
     private var altSNIContexts:Null<Array<{match:String->Bool, key:Key, cert:Certificate}>>;
     private var sniCallback:Dynamic;
     public var handshakeDone:Bool = false;
     public var secureBool:Bool = true;
     private var hostname:String;
     private override function init():Void {
         #if (cpp || neko)
         __s = NativeSocket.socket_new(false);
         #elseif (hl || hashlink)
         __s = sys.net.Socket.socket_new(false);
         #end
         input = new SocketInput(this);
         output = new SocketOutput(this);

         if (DEFAULT_VERIFY_CERT && DEFAULT_CA == null) {
             try {
                 DEFAULT_CA = Certificate.loadDefaults();
             } catch (e:Dynamic) {}
         }
         //verifyCert = 0;
         verifyCert = 1;
         caCert = DEFAULT_CA;
     }
     public function unsecure()
    {
        handshakeDone = true;
        secureBool = false;
    }
    public function secure()
    {
        //NativeSsl.ssl_set_socket(ssl, __s);
        #if (neko || cpp)
        NativeSsl.ssl_set_hostname(ssl, #if neko untyped hostname.__s #else hostname #end);
        #elseif  (hl || hashlink)
        ssl.setHostname(@:privateAccess hostname.toUtf8());
        #end
        handshakeDone = false;
        secureBool = true;
        setBlocking(true);
        handshake();
        setBlocking(false);
    }
     public override function connect(host:sys.net.Host, port:Int):Void {
		try {
            #if (cpp || neko)
            ctx = buildSSLContext(false);
            ssl = NativeSsl.ssl_new(ctx);
            
            NativeSsl.ssl_set_socket(ssl, __s);
            NativeSocket.socket_connect(__s, host.ip, port);
            #end

            #if (hl || hashlink)
            ctx = buildConfig(false);
            ssl = new Context(ctx);
            ssl.setSocket(__s);
            sys.net.Socket.socket_connect(__s,host.ip,port);
            #end
            handshake();
		} catch (s:String) {
		/*	if (s == "std@socket_connect")
				throw "Failed to connect on " + host.host + ":" + port;
            else
                #if neko 
                neko.Lib.rethrow(s);
                #elseif cpp
                cpp.Lib.rethrow(s);
                #end
		} catch (e:Dynamic) {
			#if neko 
            neko.Lib.rethrow(e);
            #elseif cpp
            cpp.Lib.rethrow(e);
            #end*/

		}
	}
 
     public function handshake():Void {
         if (!handshakeDone) {
             try {
                 #if (hl || hashlink)
                var r = ssl.handshake();
                if (r == 0)
                    handshakeDone = true;
                #elseif (neko || cpp)
                NativeSsl.ssl_handshake(ssl);
                 handshakeDone = true;
                 #end
             } catch (e:Dynamic) {
                 /*if (e == "Blocking")
                     throw haxe.io.Error.Blocked;
                 else
                    #if neko
                     neko.Lib.rethrow(e);
                    #elseif cpp
                    cpp.Lib.rethrow(e);
                    #end*/
            }
         }
     }
 
     public function setCA(cert:Certificate):Void {
         caCert = cert;
     }
 
     /*public function setHostname(name:String):Void {
         hostname = name;
     }*/
 
     public function setCertificate(cert:Certificate, key:Key):Void {
         ownCert = cert;
         ownKey = key;
     }
     #if !(hashlink || hl)
     public override function read():String {
         #if neko
         var b:String;
         #elseif cpp
         var b:BytesData;
         #end
         if (secureBool)
         {
            handshake();
            b = NativeSsl.ssl_read(ssl);
         }else{
            b = NativeSocket.socket_read(__s);
         }
         if (b == null)
             return "";
         #if neko
         return new String(cast b);
         #elseif cpp
         return haxe.io.Bytes.ofData(b).toString();
         #end
     }
     #end
     #if !(hl || hashlink)
     public override function write(content:String):Void {
         if (secureBool)
         {
            handshake();
            NativeSsl.ssl_write(ssl, #if neko untyped content.__s #elseif (cpp || hl) haxe.io.Bytes.ofString(content).getData() #end);
         }else{
            NativeSocket.socket_write(__s, #if neko untyped content.__s #elseif cpp haxe.io.Bytes.ofString(content).getData() #end);
         }
     }
     #end
 
     public override function close():Void {
         trace("CLOSE!");
         #if (cpp || neko)
         if (ssl != null)
            NativeSsl.ssl_close(ssl);
         if (ctx != null)
            NativeSsl.conf_close(ctx);
         #elseif (hl || hashlink)
         if (ssl != null)
			ssl.close();
		if (ctx != null)
			ctx.close();
         #end
         if (altSNIContexts != null)
             sniCallback = null;
         #if (neko || cpp)
         NativeSocket.socket_close(__s);
         #elseif (hl || hashlink)
         sys.net.Socket.socket_close(__s);
         #end
         var input:SocketInput = cast input;
         var output:SocketOutput = cast output;
         @:privateAccess input.__s = output.__s = null;
         input.close();
         output.close();
     }
     #if (neko || cpp)
     private function buildSSLContext(server:Bool):CTX {
         var ctx:CTX = NativeSsl.conf_new(server);
 
         if (ownCert != null && ownKey != null)
            NativeSsl.conf_set_cert(ctx, @:privateAccess ownCert.__x, @:privateAccess ownKey.__k);
 
         if (altSNIContexts != null) {
             sniCallback = function(servername) {
                 var servername = new String(cast servername);
                 for (c in altSNIContexts) {
                     if (c.match(servername))
                         return @:privateAccess {
                             key:c.key.__k, cert:c.cert.__x
                         };
                 }
                 if (ownKey != null && ownCert != null)
                     return @:privateAccess {
                         key:ownKey.__k, cert:ownCert.__x
                     };
                 return null;
             }
             NativeSsl.conf_set_servername_callback(ctx, sniCallback);
         }
 
         if (caCert != null)
            NativeSsl.conf_set_ca(ctx, caCert == null ? null : @:privateAccess caCert.__x);
        
        //NativeSsl.conf_set_verify(ctx, verifyCert);
 
         return ctx;
     }
     #end

     #if (hl || hashlink)
     private function buildConfig(server:Bool):Config {
		var conf = new Config(server);

		if (ownCert != null && ownKey != null)
			conf.setCert(@:privateAccess ownCert.__x, @:privateAccess ownKey.__k);

		if (altSNIContexts != null) {
			sniCallback = function(servername:hl.Bytes):SNICbResult {
				var servername = @:privateAccess String.fromUTF8(servername);
				for (c in altSNIContexts) {
					if (c.match(servername))
						return new SNICbResult(c.cert, c.key);
				}
				if (ownKey != null && ownCert != null)
					return new SNICbResult(ownCert, ownKey);
				return null;
			}
			conf.setServernameCallback(sniCallback);
		}

		if (caCert != null)
			conf.setCa(caCert == null ? null : @:privateAccess caCert.__x);
        //conf.setVerify(if (verifyCert) 1 else if (verifyCert == null) 2 else 0);
        conf.setVerify(0);

		return conf;
    }
    #end
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