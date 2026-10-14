import 'package:flutter/material.dart';

import 'linked_scroll.dart';

class Property {
  const Property(this.name, this.color);
  final String name;
  final Color color;
}

/// One row of the table: a label and one value per property. A value is a String, or a bool shown as a tick or cross.
class MatrixRow {
  const MatrixRow(this.label, this.values);
  final String label;
  final List<Object> values;
}

/// Layout from the carousel:
///  * the header (property names with a picture area) is pinned at the top while the rows scroll vertically
///  * the label column stays fixed on the left while columns scroll horizontally
///  * header and body scroll horizontally together, so a value is always under its own property
class ComparisonMatrix extends StatefulWidget {
  const ComparisonMatrix({
    super.key,
    required this.properties,
    required this.rows,
    this.labelWidth = 96,
    this.columnWidth = 140,
    this.rowHeight = 56,
    this.headerHeight = 132,
  });

  final List<Property> properties;
  final List<MatrixRow> rows;
  final double labelWidth;
  final double columnWidth;
  final double rowHeight;
  final double headerHeight;

  @override
  State<ComparisonMatrix> createState() => _ComparisonMatrixState();
}

class _ComparisonMatrixState extends State<ComparisonMatrix> {
  final _scroll = LinkedScrollControllers();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _FixedHeader(
            height: w.headerHeight,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 1,
              child: Row(
                children: [
                  SizedBox(width: w.labelWidth, child: const Center(child: Text('Compare', style: TextStyle(fontWeight: FontWeight.w700)))),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key('header-scroll'),
                      controller: _scroll.a,
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [for (final p in w.properties) _HeaderCell(p, width: w.columnWidth)]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed label column.
              Column(children: [for (final r in w.rows) _Cell(width: w.labelWidth, height: w.rowHeight, alignStart: true, child: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w600)))]),
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('body-scroll'),
                  controller: _scroll.b,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      for (final r in w.rows)
                        Row(children: [for (final v in r.values) _Cell(width: w.columnWidth, height: w.rowHeight, child: _value(v))]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _value(Object v) {
    if (v is bool) {
      return Icon(v ? Icons.check_circle : Icons.cancel, color: v ? Colors.green.shade700 : Colors.red.shade400, semanticLabel: v ? 'Yes' : 'No');
    }
    return Text('$v');
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.property, {required this.width});
  final Property property;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stand-in for the property photo.
              Container(height: 64, decoration: BoxDecoration(color: property.color, borderRadius: BorderRadius.circular(10)), child: const Center(child: Icon(Icons.home_work, color: Colors.white))),
              const SizedBox(height: 6),
              Text(property.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.height, required this.child, this.alignStart = false});
  final double width;
  final double height;
  final Widget child;
  final bool alignStart;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        alignment: alignStart ? Alignment.centerLeft : Alignment.center,
        padding: alignStart ? const EdgeInsets.only(left: 12) : null,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
        child: child,
      );
}

class _FixedHeader extends SliverPersistentHeaderDelegate {
  _FixedHeader({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox(height: height, child: child);

  @override
  bool shouldRebuild(covariant _FixedHeader old) => old.height != height || old.child != child;
}
