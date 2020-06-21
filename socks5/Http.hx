package socks5;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;

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
    override function customRequest(post:Bool, api:Output, ?sock:sys.net.Socket, ?method:String) {
        if (PROXY != null) Socket.PROXY = PROXY;
        sock = new Socket();
        super.customRequest(post, api, sock, method);
    }
}