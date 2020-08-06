import socks5.ProxyServer;
import sys.thread.Thread;

class ThreadProxyServer
{
    public static function create(secure:Bool)
    {
        Thread.create(function()
        {
            new ProxyServer("0.0.0.0",8005,secure).listen();
        });
    }
}