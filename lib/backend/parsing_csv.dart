import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vineburgapp/classes/tool_class.dart';
import 'package:csv/csv.dart';

class CSVPage extends StatefulWidget {
  const CSVPage({super.key});

  @override
  State<CSVPage> createState() => _CSVPageState();
}

class _CSVPageState extends State<CSVPage> {
  int currentIndex = 0;
  List<List<dynamic>> csvRows = []; // Changed to list of lists for the rows

  @override
  void initState() {
    super.initState();
    loadCsvData().then((loadedCsvRows) {
      setState(() {
        csvRows = loadedCsvRows;
      });
    });
  }

  Future<List<List<dynamic>>> loadCsvData() async {
    try {
      final fileContents =
          await rootBundle.loadString('assets/images/data.csv');
      List<List<dynamic>> rows =
          const CsvToListConverter().convert(fileContents);
      return rows; // Returns the rows as a list of lists directly
    } catch (e) {
      debugPrint('Error reading CSV file: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tool To Database'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                icon: const Icon(Icons.add_box_rounded),
                onPressed: () async {
                  for (int i = 1; i < csvRows.length; i++) {
                    // Start from 1 if the first row is headers
                    final currentRow = csvRows[i];

                    // Your processing logic here
                    String gageId = currentRow[0].toString().padLeft(5, '0');
                    await addToolWithParams(
                        currentRow[4].toString(), // calFreq
                        currentRow[7].toString(), // calLast
                        currentRow[5].toString(), // calNextDue
                        currentRow[1].toString(), // creationDate
                        gageId, // gageID with padding
                        currentRow[3].toString(), // gageType
                        '', // Placeholder for the empty parameter
                        currentRow[2].toString(), // gageDesc
                        currentRow[6].toString() // daysRemain
                        );

                    if (kDebugMode) {
                      print("Processed Gage ID: $gageId");
                    }

                    // Wait for 1 second before processing the next row
                    await Future.delayed(const Duration(seconds: 1));
                  }

                  // Once all rows have been processed
                  if (kDebugMode) {
                    print('All rows have been processed.');
                  }
                }),
          ],
        ),
      ),
    );
  }
}
