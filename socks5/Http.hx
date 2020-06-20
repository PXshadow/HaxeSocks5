package socks5;

import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;

class Http extends haxe.Http
{
    public function new(url:String)
    {
        super(url);
    }
    override function customRequest(post:Bool, api:Output, ?sock:sys.net.Socket, ?method:String) {
        super.customRequest(post, api, sock, method);
        //pass through
        
    }
    override function writeBody(body:Null<BytesOutput>, fileInput:Null<Input>, fileSize:Int, boundary:Null<String>, sock:sys.net.Socket) {
        super.writeBody(body, fileInput, fileSize, boundary, sock);
        //stop write untill finish pass through
    }
}