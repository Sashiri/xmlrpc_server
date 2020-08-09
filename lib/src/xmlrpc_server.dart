import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'package:xml_rpc/src/converter.dart';

class XmlRpcServer {
  final Map<String, Future<XmlDocument> Function(List<dynamic>)> _bindings = {};
  int _port;
  String _host;
  HttpServer _server;

  int get port => _port;
  String get host => _host;

  XmlRpcServer({String host, int port}) {
    _host = host ?? InternetAddress.loopbackIPv4.address;
    _port = port ?? 80;
  }

  void bind(
      String methodName, Future<XmlDocument> Function(List<dynamic>) callback) {
    _bindings.putIfAbsent(methodName, () => callback);
  }

  Future<XmlDocument> _handleRequest(XmlDocument document) async {
    var methodCall = document.findElements('methodCall').first;
    var methodName = methodCall.findElements('methodName').first.text;
    var method = _bindings.entries.firstWhere((x) => x.key == methodName).value;

    final params = methodCall.findElements('params');
    if (params.isNotEmpty) {
      final values = [];
      params.first.findElements('param').forEach((param) {
        final valueNode = param.findElements('value').first;
        final value = getValueContent(valueNode);
        values.add(decode(value, xml_rpc.standardCodecs));
      });
      return await method(values);
    } else {
      //TODO: Jeśli nie zostały przekazane parametry
    }

    return XmlDocument({
      XmlProcessing('xml', 'version="1.0"'),
      XmlElement(XmlName('methodResponse'), [], [])
    });
  }

  void startServer() async {
    _server = await HttpServer.bind(host, port, shared: true);
    await for (HttpRequest request in _server) {
      var xmlRequest =
          await utf8.decoder.bind(request).join().then((value) => parse(value));

      final response =
          await _handleRequest(xmlRequest).then((doc) => doc.toXmlString());

      request.response.statusCode = HttpStatus.ok;
      request.response.headers
        ..contentType = ContentType('text', 'xml')
        ..contentLength = response.length;

      request.response.write(response);
      await request.response.close();
    }
  }
}

XmlDocument generateXmlResponse(List params, {List<Codec> encodeCodecs}) {
  encodeCodecs = encodeCodecs ?? xml_rpc.standardCodecs;
  final methodCallChildren = [
    XmlElement(
        XmlName('params'),
        [],
        params.map((p) => XmlElement(XmlName('param'), [], [
              XmlElement(XmlName('value'), [], [encode(p, encodeCodecs)])
            ])))
  ];
  return XmlDocument([
    XmlProcessing('xml', 'version="1.0"'),
    XmlElement(XmlName('methodResponse'), [], methodCallChildren)
  ]);
}
