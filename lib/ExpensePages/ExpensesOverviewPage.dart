import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../DataTypes/ChartData.dart';
import '../Global.dart';
import '../DataTypes/Receipt.dart';

class ExpensesOverviewPage extends StatefulWidget {
  const ExpensesOverviewPage({Key? key}) : super(key: key);

  @override
  _UserTotalPageState createState() => _UserTotalPageState();
}

class _UserTotalPageState extends State<ExpensesOverviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Weekly Expenses"),
          backgroundColor: Global.colorBlue,
          centerTitle: true,
        ),
        body: Center(
          child: FutureBuilder(
            future: _getExpenses(),
            builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Loading...");
              } else if (snapshot.hasError) {
                return  RefreshIndicator(child: ListView(children: const [Center(heightFactor: 30,child: Text("An error occurred! Please refresh"))],), onRefresh: _onRefresh);
              } else {

                if(snapshot.data!['cumulativeReceiptCount'] == 0) {
                  return  RefreshIndicator(child: ListView(children: const [Center(heightFactor: 30,child: Text("No expenses have bee made"))],), onRefresh: _onRefresh);
                }

                return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _getExpensesListView(snapshot));
              }
            },
          ),
        ));
  }

  Widget _getExpensesListView(AsyncSnapshot<Map<String, dynamic>?> snapshot) {


    //To prevent rounding errors during maths, all expenses are stored in cents
    final double foodTotal = snapshot.data!['cumulativeFoodTotal'] / 100;
    final double toolsTotal = snapshot.data!['cumulativeToolsTotal'] / 100;
    final double travelTotal = snapshot.data!['cumulativeTravelTotal'] / 100;
    final double otherTotal = snapshot.data!['cumulativeOtherTotal'] / 100;
    final double cumulativeTotal = snapshot.data!['cumulativeReceiptTotal'] / 100;

    //ChartData only takes in a double, hence the use of toDouble()
    final double foodCount = snapshot.data!['cumulativeFoodCount'].toDouble();
    final double toolsCount = snapshot.data!['cumulativeToolsCount'].toDouble();
    final double travelCount = snapshot.data!['cumulativeTravelCount'].toDouble();
    final double otherCount = snapshot.data!['cumulativeOtherCount'].toDouble();
    final int cumulativeCount = snapshot.data!['cumulativeReceiptCount'];


    var pieChartData = <ChartData>[
      ChartData(ExpenseType.food, foodTotal, Colors.green),
      ChartData(ExpenseType.tools, toolsTotal, Colors.purple),
      ChartData(ExpenseType.travel, travelTotal, Colors.blue),
      ChartData(ExpenseType.other, otherTotal, Colors.red),
    ];

    var barChartData = <ChartData>[
      ChartData(ExpenseType.food, foodCount, Colors.green),
      ChartData(ExpenseType.tools, toolsCount, Colors.purple),
      ChartData(ExpenseType.travel, travelCount, Colors.blue),
      ChartData(ExpenseType.other, otherCount, Colors.red),
    ];

    return ListView(
      children:[
              //**************Pie Chart**********
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SfCircularChart(
                    title:
                        ChartTitle(text: "Total Expenses: \$ ${cumulativeTotal.toStringAsFixed(2)}"),
                    borderWidth: 2,
                    borderColor: Colors.black,
                    legend: Legend(
                        isVisible: true,
                        position: LegendPosition.top,
                        offset: Offset.zero),
                    series: <CircularSeries>[
                      PieSeries<ChartData, String>(
                          radius: "75%",
                          dataSource: pieChartData,
                          pointColorMapper: (ChartData data, _) => data.color,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          dataLabelMapper: (ChartData data, _) =>
                              "\$ ${data.y.toStringAsFixed(2)}",
                          legendIconType: LegendIconType.circle,
                          dataLabelSettings: const DataLabelSettings(
                            showZeroValue: false,
                            isVisible: true,
                            labelIntersectAction: LabelIntersectAction.shift,
                            overflowMode: OverflowMode.shift,
                            connectorLineSettings: ConnectorLineSettings(
                              color: Colors.black,
                              type: ConnectorType.line,
                            ),
                            labelPosition: ChartDataLabelPosition.outside,
                          ))
                    ],
                  ),
                ),
              ),
              //*****************************

              //***********BarChart**************
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  child: SfCartesianChart(
                    borderWidth: 2,
                    borderColor: Colors.black,
                    title:
                        ChartTitle(text: "Expenses Made: $cumulativeCount"),
                    primaryXAxis: CategoryAxis(
                      isVisible: true,
                    ),
                    primaryYAxis: NumericAxis(
                        interval: 1,
                        isVisible: true,
                        rangePadding: ChartRangePadding.auto),
                    series: <ChartSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        dataSource: barChartData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        pointColorMapper: (ChartData data, _) => data.color,
                      ),
                    ],
                  ),
                ),
              ),
              //**********************
            ],
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }
}

Future<Map<String, dynamic>?> _getExpenses() async {
  var cumulativeStatsRef = await FirebaseFirestore.instance.doc('cumulativeStats/cumulativeStats').get();
  return cumulativeStatsRef.data();

}
