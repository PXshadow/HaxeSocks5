package socks5;

import haxe.io.Bytes;
import sys.net.Socket;
import sys.net.Host;

class Proxy
{
    var socket:Socket;
    var host:String;
    var port:Int;
    var int:Int = 0;
    public function new(socket:Socket,host:String,port:Int)
    {
        this.socket = socket;
        this.host = host;
        this.port = port;
    }
    public function auth():Bool
    {
        //async state machine
        switch (int++)
        {
            case 0:
            authSend();
            return true;
            case 1:
            if (!authResponse()) 
            {
                int--;
                return true;
            }
            reqSend();
            case 2:
            if (!reqResponse())
            {
                int--;
                return true;
            }
        }
        return false;
    }
    private function reqSend()
    {
        var bytes = Bytes.alloc(10);
        bytes.set(0,0x05); //SOCKS version number
        bytes.set(1,0x01); //command (connect,bind,udp associate)
        bytes.set(2,0x00); //Reserved
        bytes.set(3,0x01); //address type of following address (ipv4 address,domainname,ipv6 address)

        var i = ipv4(bytes,4,new Host(host).toString()); //ip 4

        bytes.set(i++,port >> 8); //port 2
        bytes.set(i++,port & 0xff);
        //total 10
        socket.output.write(bytes);
    }
    private function reqResponse():Bool
    {
        try {
            socket.input.readByte(); //version
        }catch(e:Dynamic)
        {
            return false;
        }
        switch (socket.input.readByte())
        {
            case 0x00:
            //succeeded
            socket.input.read(8);
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
        }
        close();
        return true;
    }
    private function ipv4(bytes:Bytes,pos:Int,ip:String):Int
    {
        for (part in ip.split("."))
        {
            var byte:UInt = Std.parseInt(part);
            bytes.set(pos++,byte);
        }
        return pos;
    }
    private function authSend()
    {
        var bytes = Bytes.alloc(3);
        bytes.set(0,0x05); //SOCKS version number
        bytes.set(1,0x02); //0x01 for digest (SASL and DIGEST-MD5 for XMPP)
        bytes.set(2,0x00); //Authentication methods, 1 byte per method supported
        socket.output.write(bytes);
    }
    private function authResponse():Bool
    {
        socket.input.readByte(); //version
        var cauth = socket.input.readByte();//chosen authentication method
        return switch (cauth)
        {
            case 0x00:
            //no authentication
            true;
            case 0x01:
            //user/password authentication TODO
            trace("username password authentication not support yet");
            false;
            case 0xFF: 
            trace("no acceptable authentication method offered");
            false;
            default: 
            trace('cauth not found $cauth');
            false;
        }
    }
    private function close()
    {
        int = 3;
    }

}