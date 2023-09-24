import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final counterProvider =
    StateNotifierProvider<MainLogic, String>((_) => MainLogic());

class MainLogic extends StateNotifier<String> {
  MainLogic() : super("https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg?auto=compress&cs=tinysrgb&w=1600");

  Future<String> getImgUrl() async {
    var client = HttpClient();
    var uri = Uri.parse('https://api.thecatapi.com/v1/images/search');
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    var data = await response.transform(utf8.decoder).join();
    var map = json.decode(data);
    return map[0]['url'].toString();
  }

  Future<String> getImgUrlIsolate() async {
    final url = await getImgUrl(); 
    final isolate = await Isolate.run<String>(() => url);
    state = isolate;
    return state;
  }

  Stream<Map<String, dynamic>> _sendAndReceive(List<String> filenames) async* {
  final p = ReceivePort();
  await Isolate.spawn(_readAndParseJsonService, p.sendPort);

  // Convert the ReceivePort into a StreamQueue to receive messages from the
  // spawned isolate using a pull-based interface. Events are stored in this
  // queue until they are accessed by `events.next`.
  final events = StreamQueue<dynamic>(p);

  // The first message from the spawned isolate is a SendPort. This port is
  // used to communicate with the spawned isolate.
  SendPort sendPort = await events.next;

  for (var filename in filenames) {
    // Send the next filename to be read and parsed
    sendPort.send(filename);

    // Receive the parsed JSON
    Map<String, dynamic> message = await events.next;

    // Add the result to the stream returned by this async* function.
    yield message;
  }

  // Send a signal to the spawned isolate indicating that it should exit.
  sendPort.send(null);

  // Dispose the StreamQueue.
  await events.cancel();
}

  Future<void> _readAndParseJsonService(SendPort p) async {
  // Send a SendPort to the main isolate so that it can send JSON strings to
  // this isolate.
  final commandPort = ReceivePort();
  p.send(commandPort.sendPort);
  // Wait for messages from the main isolate.
  await for (final message in commandPort) {
    if (message is String) {
      // Read and decode the file.
      final contents = await File(message).readAsString();
      // Send the result to the main isolate.
      p.send(jsonDecode(contents));
    } else if (message == null) {
      // Exit if the main isolate sends a null message, indicating there are no
      // more files to read and parse.
      break;
    }
  }
  Isolate.exit();
}
}
