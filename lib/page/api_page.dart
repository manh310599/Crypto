import 'dart:async';
import 'dart:convert';

import 'package:bloc_bitcon/model/crypto_symbols.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    final header = <String, String>{'X-Api-Key': '${apiKey}'};
    final response = await http.get(
        Uri.parse('https://api.api-ninjas.com/v1/cryptosymbols?'),
        headers: header);
    final data = CryptoSymbols.fromJson(jsonDecode(response.body));
    final List<String> symbolData = data.symbols!;
    print(symbolData.length);

    final sublist = symbolData.sublist(index, batchSize);
    streamController.sink.add(sublist);

    coinPrice(sublist);

    index = 10;

    _isScrollEnd = true;
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
    final header = <String, String>{'X-Api-Key': '${apiKey}'};
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
      await Future.delayed(Duration(seconds: 1));
      _isScrollEnd = true;

      index = index + batchSize;
      print(index);
    }
  }

  coinPrice(List<String> id) async {
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
    streamPriceCoin.add(dataTam);
  }

  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return StreamBuilder<List<String>>(
      stream: streamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          data.addAll(snapshot.data!);
          return Center(
            child: Container(
                height: 500,
                child: StreamBuilder<List<DataModelPrice>>(
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      dataPrice.addAll(snapshot.data!);
                      return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          controller: controller,
                          itemBuilder: (context, index) {
                            return Container(
                              height: 300,
                              width: width / 3,
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/bitcoin.png',
                                    width: width / 5,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    dataPrice[index].symbol.toString(),
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    dataPrice[index].price.toString() + "dola",
                                    style: TextStyle(color: Colors.yellow),
                                  )
                                ],
                              ),
                            );
                          },
                          itemCount: dataPrice.length);
                    } else {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                  stream: streamPriceCoin.stream,
                )),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
