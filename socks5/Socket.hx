package socks5;

import sys.net.Host;
import socks5._internal.UpgradeSocket;

class Socket extends UpgradeSocket
{
    public static var PROXY:{host:String, port:Int, auth:{user:String, pass:String}} = null;
    public var secure:Bool = true; //after protocol auth, should upgrade socket to ssl
    var proxy:Proxy;
    var blocking:Bool = true;
    public var connected:Bool = false;
    public function new()
    {
        super();
    }
    override function connect(host:Host, port:Int) 
    {
        if (PROXY != null)
        {
            hostname = host.host;
            super.connect(new Host(PROXY.host),PROXY.port);
            proxy = new Proxy(this,host.host,port);
        }else{
            super.connect(host, port);
        }
    }
    override function setBlocking(b:Bool) {
        blocking = b;
        super.setBlocking(b);
    }
    public function auth():Bool
    {
        if (proxy == null) return true;
        if (!connected && !proxy.auth()) return false;
        return connected = true;
    }
}