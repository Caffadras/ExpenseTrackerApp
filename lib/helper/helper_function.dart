import 'package:intl/intl.dart';

double toDouble(String input){
  double? tryParse = double.tryParse(input);
  return tryParse ?? 0;
}

String formatAmount(double number){
  final format = NumberFormat.currency(locale: "en_US", symbol: "\$", decimalDigits: 2);
  return format.format(number);
}

int calculateMonthCount(int startYear, int startMonth, int currYear, int currMonth){
  // DateTime(startYear, startMonth).difference(DateTime(currYear, currMonth)).inDays / 30;
  // print("##############CURY " + currYear.toString());
  // print("##############STARTY " + startYear.toString());
  // print("##############CURRM " + currMonth.toString());
  // print("##############STARTM " + startMonth.toString());

  var result = (currYear - startYear) * 12 + currMonth - startMonth + 1;
  // print("##############REULS " + result.toString());
  return result;
}