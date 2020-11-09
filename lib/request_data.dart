class RequestData {
  String title;
  String name;
  String barcode;
  String dist;
  String price;
  String quantity;
  String timeStamp;

  RequestData(
      {this.title,
      this.name,
      this.barcode = "",
      this.dist = "",
      this.price = "0",
      this.quantity = "0",
      this.timeStamp});
}
