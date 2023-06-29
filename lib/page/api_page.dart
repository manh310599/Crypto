import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:bloc_bitcon/model/crypto_symbols.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../common.dart';
import '../model/data_model_price.dart';

class ApiPage extends StatefulWidget {
  const ApiPage({Key? key}) : super(key: key);

  @override
  State<ApiPage> createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  bool _isScrollEnd = false;
  StreamController<List<String>> streamController = StreamController();
  StreamController<List<DataModelPrice>> streamPriceCoin = StreamController();

  final batchSize = 10;
  var index = 0;
  final List<DataModelPrice> dataPrice = [];
  List<String> data = [];

  Future<void> fetchData() async {
    String url = 'https://api.api-ninjas.com/v1/cryptosymbols?';
    final header = <String, String>{'X-Api-Key': apiKey};
    // Kiểm tra xem dữ liệu có trong cache hay không
    File cachedFile = await DefaultCacheManager().getSingleFile(url,headers: header);

    if (cachedFile.existsSync()) {
      // Dữ liệu đã được lưu trữ trong cache
      String cachedData = cachedFile.readAsStringSync();
      final data = CryptoSymbols.fromJson(jsonDecode(cachedData));
      final List<String> symbolData = data.symbols!;


      final sublist = symbolData.sublist(index, batchSize);
      streamController.sink.add(sublist);

      coinPrice(sublist);

      index = 10;

      _isScrollEnd = true;
    } else {
      // Dữ liệu không có trong cache
      // Thực hiện các hành động khác, ví dụ: Gọi API để lấy dữ liệu mới

      final response = await http.get(Uri.parse(url), headers: header);
      final data = CryptoSymbols.fromJson(jsonDecode(response.body));
      final List<String> symbolData = data.symbols!;


      final sublist = symbolData.sublist(index, batchSize);
      streamController.sink.add(sublist);

      coinPrice(sublist);

      index = 10;

      _isScrollEnd = true;

      String dataToCache = response.body;
      Uint8List bytes = Uint8List.fromList(utf8.encode(dataToCache));
      DefaultCacheManager().putFile(url, bytes); // Lưu trữ dữ liệu vào cache
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    controller.addListener(() {
      console();
    });
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
    streamController.close();
    streamPriceCoin.close();
    controller.dispose();
  }

  ScrollController controller = ScrollController();

  console() async {
    final header = <String, String>{'X-Api-Key': apiKey};
    final response = await http.get(
        Uri.parse('https://api.api-ninjas.com/v1/cryptosymbols?'),
        headers: header);
    final data = CryptoSymbols.fromJson(jsonDecode(response.body));
    final List<String> symbolData = data.symbols!;

    if (controller.offset >= controller.position.maxScrollExtent &&
        _isScrollEnd == true &&
        index < symbolData.length) {
      final endIndex = index + batchSize;
      final sublist = symbolData.sublist(
          index, endIndex > symbolData.length ? symbolData.length : endIndex);

      streamController.sink.add(sublist);

      coinPrice(sublist);

      _isScrollEnd = false;
      await Future.delayed(const Duration(seconds: 1));
      _isScrollEnd = true;

      index = index + batchSize;
    }
  }

  coinPrice(List<String> id) async {
    // final List<DataModelPrice> dataTam = [];
    // final heder = <String, String>{'X-Api-Key': apiKey};
    // for (int i = 0; i < id.length; i++) {
    //   final reponse = await http.get(
    //       Uri.parse(
    //           'https://api.api-ninjas.com/v1/cryptoprice?symbol=${id[i]}'),
    //       headers: heder);
    //   final data = DataModelPrice.fromJson(jsonDecode(reponse.body));
    //
    //   //await Future.delayed(Duration(milliseconds: 500));
    //   dataTam.add(data);
    // }
    // streamPriceCoin.add(dataTam);
    createIsolate(id);
  }

  void createIsolate(List<String> id) {
    var receivePort = ReceivePort();
    Isolate.spawn(taskRunner, {
      'sendPort': receivePort.sendPort,
      'id': id,
    });

    receivePort.listen((message) {
      streamPriceCoin.add(message);
    });
  }

  static Future<void> taskRunner(dynamic message) async {
    var sendPort = message['sendPort'] as SendPort;
    var id = message['id'] as List<String>;

    final List<DataModelPrice> dataTam = [];
    final heder = <String, String>{'X-Api-Key': apiKey};
    for (int i = 0; i < id.length; i++) {
      final reponse = await http.get(
          Uri.parse(
              'https://api.api-ninjas.com/v1/cryptoprice?symbol=${id[i]}'),
          headers: heder);
      final data = DataModelPrice.fromJson(jsonDecode(reponse.body));

      //await Future.delayed(Duration(milliseconds: 500));
      dataTam.add(data);
    }
    sendPort.send(dataTam);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return StreamBuilder<List<String>>(
      stream: streamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          data.addAll(snapshot.data!);
          return Center(
            child: SizedBox(
                height: 500,
                child: StreamBuilder<List<DataModelPrice>>(
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      dataPrice.addAll(snapshot.data!);
                      return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          controller: controller,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              height: 300,
                              width: width / 3,
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/bitcoin.png',
                                    width: width / 5,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    dataPrice[index].symbol.toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "${dataPrice[index].price}dola",
                                    style: const TextStyle(color: Colors.yellow),
                                  )
                                ],
                              ),
                            );
                          },
                          itemCount: dataPrice.length);
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                  stream: streamPriceCoin.stream,
                )),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
