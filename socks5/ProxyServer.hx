package socks5;
import haxe.io.Error;
import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;
import sys.ssl.Socket as SSLSocket;
class ProxyServer
{
    var server:Socket;
    var socket:Socket;
    var client:Socket;
    var host:String;
    var port:Int;
    var secureStart:Bool; //client -> proxy
    var secureEnd:Bool; //proxy -> server
    public function new(host:String,port:Int,secureStart:Bool=false,secureEnd:Bool=true)
    {
        this.host = host;
        this.port = port;
        this.secureStart = secureStart;
    }
    public function listen()
    {
        server = secureStart ? new SSLSocket() : new Socket();
        if (secureStart) cast(server,SSLSocket).verifyCert = false;
        server.bind(new Host(host),port);
        server.listen(1);
        trace("proxy server " + host + ":" + port);
        client = server.accept();
        if (secureStart) 
        {
            trace("handshake");
            cast(client,SSLSocket).handshake();
        }
        if (!request()) throw "request failed";
        while (true)
        {
            update();
            //Sys.sleep(1/10000000);
        }
    }
    private function request():Bool
    {
        trace("request");
        if (!req()) return false;
        trace("finish auth");
        if (!auth()) return false;
        //config
        client.setBlocking(false); //client -> proxy
        socket.setBlocking(false); //proxy -> server
        return true;
    }
    public function update()
    {
        try {
            //trace("i " + client.input.readByte());
            socket.output.writeByte(client.input.readByte());
        }catch(e:Dynamic)
        {
            if (e != Error.Blocked) throw 'failed client $e';
        }
        try {
            client.output.writeByte(socket.input.readByte());
        }catch(e:Dynamic)
        {
            if (e != Error.Blocked) throw 'failed socket $e';
        }
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
        trace("try bytes");
        var bytes = client.input.read(4);
        trace("get bytes");
        bytes.get(0); //version
        bytes.get(1); //command (connect,bind,udp associate)
        bytes.get(2); //Reserved
        var type = bytes.get(3);
        switch (type) //address type of following address (ipv4 address,domainname,ipv6 address)
        {
            case 0x01: //ipv4
            bytes = client.input.read(6); //ip 4, port 2
            host = ipv4(bytes.sub(0,4));
            trace("host: " + host);
            port = ((bytes.get(4) & 0xff) << 8) | (bytes.get(5) & 0xff);
            trace("port " + port);
            default:
            trace('address type not supported $bytes');
        }
        socket = secureEnd ? new SSLSocket() : new Socket();
        if (secureEnd) cast(socket,SSLSocket).verifyCert = false;
        socket.connect(new Host(host),port);
        client.output.writeByte(0x05); //version
        client.output.writeByte(0x00); //sucess
        client.output.writeByte(0x00); //reserve
        client.output.writeByte(type);
        switch (type)
        {
            case 0x01: //ipv4
            client.output.writeBytes(bytes,0,bytes.length);
        }
            /*case 0x01: trace("general SOCKS server failure");
            case 0x02: trace("connection not allowed by ruleset");
            case 0x03: trace("Network unreachable");
            case 0x04: trace("Host unreachable");
            case 0x05: trace("Connection refused");
            case 0x06: trace("TTL expired");
            case 0x07: trace("Command not supported");
            case 0x08: trace("Address type not supported");
            case 0x09: trace("to X'FF' unassigned");*/
        return true;
    }
    private inline function ipv4(bytes:Bytes):String
    {
        trace("length " + bytes.length);
        var string = "";
        for (i in 0...4)
        {
            string += bytes.get(i) + ".";
        }
        return string.substring(0,string.length - 1);
    }
    public function bind()
    {
        listen();
    }
}