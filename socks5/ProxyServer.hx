package socks5;
import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;
import sys.ssl.Socket as SSLSocket;
class ProxyServer
{
    var socket:Socket;
    var client:Socket;
    var host:String;
    var port:Int;
    var secure:Bool;
    public function new(host:String,port:Int,secure:Bool=true)
    {
        this.host = host;
        this.port = port;
        this.secure = secure;
    }
    public function listen()
    {
        socket = secure ? new SSLSocket() : new Socket();
        if (secure) cast(socket,SSLSocket).verifyCert = false;
        socket.bind(new Host(host),port);
        socket.listen(1);
        trace("proxy server " + host + ":" + port);
        client = socket.accept();
        if (secure) cast(socket,SSLSocket).handshake();
        request();
    }
    private function request():Bool
    {
        trace("request");
        if (!auth()) return false;
        if (!req()) return false;
        return true;
    }
    private function req():Bool
    {
        var bytes = client.input.read(3);
        trace("version: " + bytes.get(0));
        trace("auth: " + bytes.get(2));
        var data = Bytes.alloc(2);
        data.set(0,5); //version
        data.set(1,0); //auth method
        client.output.write(data);
        return true;
    }
    private function auth():Bool
    {
        var bytes = client.input.read(10);
        bytes.get(0); //version
        bytes.get(1); //command (connect,bind,udp associate)
        bytes.get(2); //Reserved
        switch (bytes.get(3)) //address type of following address (ipv4 address,domainname,ipv6 address)
        {
            case 0x01: //ipv4
            default:
            trace('address type not supported $bytes');
        }
        /*switch (socket.input.readByte())
        {
            case 0x00:
            //succeeded
            socket.input.readBytes(Bytes.alloc(8),0,8);
            return true;
            case 0x01: trace("general SOCKS server failure");
            case 0x02: trace("connection not allowed by ruleset");
            case 0x03: trace("Network unreachable");
            case 0x04: trace("Host unreachable");
            case 0x05: trace("Connection refused");
            case 0x06: trace("TTL expired");
            case 0x07: trace("Command not supported");
            case 0x08: trace("Address type not supported");
            case 0x09: trace("to X'FF' unassigned");
        }*/
        return true;
    }
    private function ipv4(bytes:Bytes):String
    {
        return "";
    }
    public function bind()
    {
        listen();
    }
}