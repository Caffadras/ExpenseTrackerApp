import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';

class ExpenseDatabase extends ChangeNotifier{
  static late Isar isar;
  final List<Expense> _allExpenses = [];

  static Future<void> init() async{
    final Directory dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  List<Expense> get allExpenses => _allExpenses;

  Future<void> saveExpense(Expense newExpense) async{
    await isar.writeTxn(() => isar.expenses.put(newExpense));

    await readExpenses();
  }

  Future<void> updateExpense(int id, Expense updatedExpense) async{
    updatedExpense.id = id;
    await saveExpense(updatedExpense);
  }



  Future<void> readExpenses() async{
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);

    notifyListeners();
  }

  Future<void> deleteExpense(int id) async{
    await isar.writeTxn(() => isar.expenses.delete(id));
    await readExpenses();
  }


  Future<Map<int, double>> calculateMonthlyTotals() async{
    await readExpenses();

    Map<int, double> monthlyTotals = {};
    for (Expense expense in _allExpenses) {
      int month = expense.date.month;
      monthlyTotals.putIfAbsent(month, () => expense.amount);
      monthlyTotals[month] = monthlyTotals[month]! + expense.amount ;
    }

    return monthlyTotals;
  }


  int getStartMonth(){
    if (_allExpenses.isEmpty){
      return DateTime.now().month;
    }

    sortExpensesByDate();

    return _allExpenses.first.date.month;
  }


  int getStartYear(){
    if (_allExpenses.isEmpty){
      return DateTime.now().year;
    }
    sortExpensesByDate();

    return _allExpenses.first.date.year;
  }

  void sortExpensesByDate() {
    //todo should we copy and sort a separate array?
    _allExpenses.sort((a, b)=> a.date.compareTo(b.date));
  }

  Future<double> calculateCurrentMonthTotal() async {
    await readExpenses();
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    List<Expense> currMonthExpenses = _allExpenses.where((expense) {
      return expense.date.month == currentMonth && expense.date.year == currentYear;
    }).toList();

    double total = currMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);
    return total;
  }


}