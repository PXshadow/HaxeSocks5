import socks5.ProxyServer;
import sys.thread.Thread;

class ThreadProxyServer
{
    public static function create(secureStart:Bool=false,secureEnd:Bool=false)
    {
        Thread.create(function()
        {
            new ProxyServer("0.0.0.0",8005,secureStart,secureEnd).listen();
        });
    }
}