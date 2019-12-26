import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'package:xml_rpc/src/converter.dart';

class XmlRpcServer {
  final Map<String, Future<xml.XmlDocument> Function(List<dynamic>)> _bindings =
      {};
  int _port;
  String _host;
  HttpServer _server;

  int get port => _port;
  String get host => _host;

  XmlRpcServer({InternetAddress host, int port}) {
    _host = host.address;
    _port = port;
  }

  void bind(String methodName,
      Future<xml.XmlDocument> Function(List<dynamic>) callback) {
    _bindings.putIfAbsent(methodName, () => callback);
  }

  Future<xml.XmlDocument> _handleRequest(xml.XmlDocument document) async {
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

    return xml.XmlDocument({
      xml.XmlProcessing('xml', 'version="1.0"'),
      xml.XmlElement(xml.XmlName('methodResponse'), [], [])
    });
  }

  void startServer() async {
    _server = await HttpServer.bind(host, port, shared: true);
    await for (HttpRequest request in _server) {
      var xmlRequests = [];
      await utf8.decoder
          .bind(request)
          .forEach((x) => xmlRequests.add(xml.parse(x)));

      await xmlRequests.forEach((_) async {
        final response = await _handleRequest(xmlRequests.first)
            .then((doc) => doc.toXmlString());
        request.response.write(response);
      });
      return request.response.close();
    }
  }
}

xml.XmlDocument generateXmlResponse(List params, {List<Codec> encodeCodecs}) {
  encodeCodecs = encodeCodecs ?? xml_rpc.standardCodecs;
  final methodCallChildren = [
    xml.XmlElement(
        xml.XmlName('params'),
        [],
        params.map((p) => xml.XmlElement(xml.XmlName('param'), [], [
              xml.XmlElement(
                  xml.XmlName('value'), [], [encode(p, encodeCodecs)])
            ])))
  ];
  return xml.XmlDocument([
    xml.XmlProcessing('xml', 'version="1.0"'),
    xml.XmlElement(xml.XmlName('methodResponse'), [], methodCallChildren)
  ]);
}
