package socks5;

import sys.net.Host;

class Socket extends UpgradeSocket
{
    public static var PROXY:{host:String, port:Int, auth:{user:String, pass:String}} = null;
    public var secure:Bool = true; //after protocol auth, should upgrade socket to ssl
    var proxy:Proxy;
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
            trace("start proxy request");
            if (!proxy.request()) return;
            if (secure) upgrade();
        }else{
            super.connect(host, port);
        }
    }
}