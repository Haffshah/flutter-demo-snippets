import 'package:flutter/material.dart';

import 'comparison_matrix.dart';

void main() => runApp(const DemoApp());

const demoProperties = [
  Property('Property A', Color(0xFF2D5A27)),
  Property('Property B', Color(0xFF3F6FA8)),
  Property('Property C', Color(0xFFB5651D)),
  Property('Property D', Color(0xFF7B4FA0)),
];

// Fake data only.
const demoRows = [
  MatrixRow('Rent', [r'$2.1k', r'$1.8k', r'$2.4k', r'$1.6k']),
  MatrixRow('SqFt', ['1,200', '950', '1,350', '800']),
  MatrixRow('Pool', [true, false, true, false]),
  MatrixRow('Gym', [true, true, false, false]),
  MatrixRow('Parking', [true, true, true, false]),
  MatrixRow('Pets', [true, false, true, true]),
  MatrixRow('Laundry', [false, true, true, false]),
  MatrixRow('Balcony', [true, false, false, true]),
  MatrixRow('Elevator', [true, true, false, false]),
  MatrixRow('Furnished', [false, false, true, true]),
  MatrixRow('Bedrooms', ['2', '1', '3', '1']),
  MatrixRow('Bathrooms', ['2', '1', '2', '1']),
  MatrixRow('Floor', ['4', '2', '7', '1']),
  MatrixRow('Built', ['2018', '2009', '2021', '1998']),
];

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Comparison matrix demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2D5A27)),
        home: Scaffold(
          appBar: AppBar(title: const Text('Compare properties')),
          body: const ComparisonMatrix(properties: demoProperties, rows: demoRows),
        ),
      );
}
