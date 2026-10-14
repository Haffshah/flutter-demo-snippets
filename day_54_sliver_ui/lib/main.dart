import 'package:flutter/material.dart';

import 'theme.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sliver UI demo',
        debugShowCheckedModeBanner: false,
        theme: Tokens.theme(),
        home: const CouponListScreen(),
      );
}

class Coupon {
  const Coupon(this.merchant, this.title, this.code, this.status);
  final String merchant;
  final String title;
  final String code;
  final String status; // active | expired | used
}

const _coupons = <Coupon>[
  Coupon('Swiggy', 'Flat 250 off on your next order', 'SWIGGY250', 'active'),
  Coupon('Myntra', 'Extra 15% off on fashion', 'MYNTRA15', 'active'),
  Coupon('Amazon Pay', 'Flat 50 cashback on bill payment', 'AMZ50', 'used'),
  Coupon('Zomato', '20% off up to 100', 'ZOMATO20', 'expired'),
  Coupon('CRED', 'Gift card reward', 'CRED100', 'active'),
  Coupon('PhonePe', 'Scratch card cashback', 'PHONE30', 'expired'),
  Coupon('Paytm', 'Movie ticket offer', 'PAYTM75', 'active'),
  Coupon('Swiggy', 'Instamart 10% off', 'INSTA10', 'active'),
];

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  String _query = '';
  String _status = 'all';

  List<Coupon> get _visible => _coupons.where((c) {
        final q = _query.toLowerCase();
        final matchesQuery = q.isEmpty ||
            c.merchant.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q);
        final matchesStatus = _status == 'all' || c.status == _status;
        return matchesQuery && matchesStatus;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1) Pinned app bar.
            const SliverAppBar(pinned: true, title: Text('My Coupons')),

            // 2) Pinned header: search + status chips. Fixed height, so min == max extent.
            SliverPersistentHeader(
              pinned: true,
              delegate: FixedHeaderDelegate(
                height: 112,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search coupons, codes, merchants...',
                          hintStyle: const TextStyle(color: Tokens.textMuted),
                          prefixIcon: const Icon(Icons.search, color: Tokens.textMuted),
                          filled: true,
                          fillColor: Tokens.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        children: [
                          for (final s in const ['all', 'active', 'used', 'expired'])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(s),
                                selected: _status == s,
                                onSelected: (_) => setState(() => _status = s),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3) The list itself.
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No coupons match', style: TextStyle(color: Tokens.textSecondary))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CouponCard(coupon: items[i]),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CouponCard extends StatelessWidget {
  const CouponCard({super.key, required this.coupon});
  final Coupon coupon;

  Color get _statusColor => switch (coupon.status) {
        'expired' => Tokens.statusExpired,
        'used' => Tokens.statusUsed,
        _ => Tokens.statusActive,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Tokens.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _statusColor, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coupon.merchant, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(coupon.title, style: const TextStyle(color: Tokens.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(coupon.code, style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

/// Fixed-height header for a pinned SliverPersistentHeader (minExtent == maxExtent).
class FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  FixedHeaderDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: height, child: ColoredBox(color: Tokens.bgDark, child: child));

  @override
  bool shouldRebuild(covariant FixedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
