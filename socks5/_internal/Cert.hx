package socks5._internal;
import sys.io.Process;
class Cert
{
    public static function main()
    {
        Sys.command("openssl req -x509 -sha256 -nodes -days 365" +
        " -newkey rsa:4096 -keyout private.key -out certificate.crt" +
        " -subj=/CN=foo.socks5.com"
        );
    }
}