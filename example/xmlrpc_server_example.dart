import 'package:xmlrpc_server/xmlrpc_server.dart';

void main() {
  var rpcserver = XmlRpcServer();
  rpcserver.bind('hello_world', (params) async {
    print(params);
    return generateXmlResponse([1]);
  });
  rpcserver.startServer();
}
