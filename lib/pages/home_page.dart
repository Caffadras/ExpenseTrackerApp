import 'dart:ffi';

import 'package:expense_tracker_app/bar%20graph/bar.dart';
import 'package:expense_tracker_app/components/list_tile.dart';
import 'package:expense_tracker_app/database/expense_database.dart';
import 'package:expense_tracker_app/helper/helper_function.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  static const FORMAT = 'yyyy-MM-dd';

  Future<Map<int, double>>? _monthlyTotalsFuture;
  Future<double>? _currMonthTotal;

  DateTime? selectedDate;

  @override
  void initState() {
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    refreshGraphData();
    super.initState();

    if (selectedDate != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  void refreshGraphData() {
    var database = Provider.of<ExpenseDatabase>(context, listen: false);
    _monthlyTotalsFuture = database.calculateMonthlyTotals();

    _currMonthTotal = database.calculateCurrentMonthTotal();
  }

  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: "Name",
              ),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                hintText: "Amount",
              ),
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    hintText: "Select Date",
                  ),
                  onTap: () => _selectDate(context),
                ),
              ),
            ),
          ],
        ),
        actions: [
          _cancelButton(),
          _createExpenseButton(),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      dateController.text = DateFormat(FORMAT).format(selectedDate!);
    }
  }

  void openEditExpenseBox(Expense expense) {
    final String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController..text = existingName,
              decoration: InputDecoration(
                hintText: existingName,
              ),
            ),
            TextField(
              controller: amountController..text = existingAmount,
              decoration: InputDecoration(
                hintText: existingAmount,
              ),
            ),
          ],
        ),
        actions: [
          _cancelButton(),
          _saveEditExpenseButton(expense),
        ],
      ),
    );
  }

  void openDeleteExpenseBox(Expense expense) {
    String existingName = expense.name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete expense $existingName?"),
        actions: [
          _cancelButton(),
          _deleteExpenseButton(expense),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        int startYear = value.getStartYear();
        int startMonth = value.getStartMonth();
        int currYear = DateTime.now().year;
        int currMonth = DateTime.now().month;

        int monthCount = 12;

        // int monthCount =
        //    calculateMonthCount(startYear, startMonth, currYear, currMonth);

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: openNewExpenseBox,
            child: const Icon(Icons.add),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text("Visualize your expenses:"),
          ),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: FutureBuilder(
                      future: _monthlyTotalsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final monthlyTotals = snapshot.data ?? {};

                          List<double> monthlySummary = List.generate(
                              monthCount,
                              (index) =>
                                  monthlyTotals[startMonth + index] ?? 0.0);

                          return MyBarGraph(
                              monthlySummary: monthlySummary,
                              startMonth: startMonth);
                        } else {
                          return const Center(
                            child: Text("Loading..."),
                          );
                        }
                      }),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: Row(
                    children: [
                      Text(
                        "Your expenses: ",
                        style: TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: value.allExpenses.length,
                    itemBuilder: (context, index) {
                      int reversedIndex = value.allExpenses.length - 1 - index;
                      Expense expense = value.allExpenses[reversedIndex];

                      return MyListTile(
                        title: expense.name,
                        trailing: formatAmount(expense.amount),
                        onEditPressed: (context) => openEditExpenseBox(expense),
                        onDeletePressed: (context) =>
                            openDeleteExpenseBox(expense),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        nameController.clear();
        amountController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  Widget _createExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isEmpty ||
            amountController.text.isEmpty ||
            dateController.text.isEmpty) {
          //todo
        } else {
          //todo validate amount, add date field

          Navigator.pop(context);

          DateFormat format = DateFormat(FORMAT);
          DateTime selectedDate = format.parse(dateController.text);

          Expense newExpense = Expense(
            name: nameController.text,
            amount: toDouble(amountController.text),
            date: selectedDate,
          );

          await context.read<ExpenseDatabase>().saveExpense(newExpense);

          refreshGraphData();
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  Widget _saveEditExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isEmpty || amountController.text.isEmpty) {
          //todo
        } else {
          Navigator.pop(context);

          Expense newExpense = Expense(
            name: nameController.text,
            amount: toDouble(amountController.text),
            date: expense.date,
          );

          Id existingId = expense.id;
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, newExpense);

          refreshGraphData();
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  Widget _deleteExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        Navigator.pop(context);
        await context.read<ExpenseDatabase>().deleteExpense(expense.id);
        refreshGraphData();
      },
      child: const Text("Delete"),
    );
  }
}
