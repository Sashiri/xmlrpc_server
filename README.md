A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:xmlrpc_server/xmlrpc_server.dart';

void main() {
  var rpcserver = XmlRpcServer();
  rpcserver.bind('hello_world', (params) async {
    print(params);
    return generateXmlResponse([1]);
  });
  rpcserver.startServer();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Sashiri/xmlrpc_server/issues
