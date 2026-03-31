import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final router = Router();

  router.get('/api/health', (Request request) {
    return Response.ok('{"status": "ok"}',
        headers: {'content-type': 'application/json'});
  });

  router.get('/api/executives', (Request request) {
    return Response.ok('[]',
        headers: {'content-type': 'application/json'});
  });

  router.get('/api/calls', (Request request) {
    return Response.ok('[]',
        headers: {'content-type': 'application/json'});
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on http://${server.address.host}:${server.port}');
}
