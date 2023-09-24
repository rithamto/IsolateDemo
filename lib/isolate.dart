import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
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
}
