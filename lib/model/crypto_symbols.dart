class CryptoSymbols {
  List<String>? symbols;

  CryptoSymbols({this.symbols});

  CryptoSymbols.fromJson(Map<String, dynamic> json) {
    symbols = json['symbols'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['symbols'] = this.symbols;
    return data;
  }
}
