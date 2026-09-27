import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EbolWashpointApp());
}

class EbolWashpointApp extends StatelessWidget {
  const EbolWashpointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EBOL WASHPOINT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomePage(),
    );
  }
}

class Sale {
  final String vehicle;
  final List<String> services;
  final int total;
  final DateTime date;

  Sale({
    required this.vehicle,
    required this.services,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'vehicle': vehicle,
        'services': services,
        'total': total,
        'date': date.toIso8601String(),
      };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        vehicle: j['vehicle'],
        services: List<String>.from(j['services']),
        total: j['total'],
        date: DateTime.parse(j['date']),
      );
}

class Expense {
  final String category;
  final String note;
  final int amount;
  final DateTime date;

  Expense({
    required this.category,
    required this.note,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'note': note,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        category: j['category'],
        note: j['note'],
        amount: j['amount'],
        date: DateTime.parse(j['date']),
      );
}

class AppStore extends ChangeNotifier {
  List<Sale> sales = [];
  List<Expense> expenses = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('sales');
    final e = p.getString('expenses');
    if (s != null) {
      sales = (jsonDecode(s) as List)
          .map((x) => Sale.fromJson(Map<String, dynamic>.from(x)))
          .toList();
    }
    if (e != null) {
      expenses = (jsonDecode(e) as List)
          .map((x) => Expense.fromJson(Map<String, dynamic>.from(x)))
          .toList();
    }
    notifyListeners();
  }

  Future<void> addSale(Sale sale) async {
    sales.insert(0, sale);
    await _save();
  }

  Future<void> addExpense(Expense expense) async {
    expenses.insert(0, expense);
    await _save();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sales', jsonEncode(sales.map((x) => x.toJson()).toList()));
    await p.setString(
        'expenses', jsonEncode(expenses.map((x) => x.toJson()).toList()));
    notifyListeners();
  }
}

final store = AppStore();

String rupiah(int n) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(n);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onKasir: () => setState(() => index = 1)),
      const KasirPage(),
      const TransactionsPage(),
      const ExpensesPage(),
      const ReportsPage(),
    ];

    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => Scaffold(
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Transaksi'),
            NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Biaya'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final VoidCallback onKasir;
  const DashboardPage({super.key, required this.onKasir});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todaySales = store.sales.where((x) =>
        x.date.year == now.year &&
        x.date.month == now.month &&
        x.date.day == now.day);
    final todayExp = store.expenses.where((x) =>
        x.date.year == now.year &&
        x.date.month == now.month &&
        x.date.day == now.day);
    final omzet = todaySales.fold<int>(0, (a, b) => a + b.total);
    final biaya = todayExp.fold<int>(0, (a, b) => a + b.amount);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('EBOL WASHPOINT',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: StatCard('Omzet Hari Ini', rupiah(omzet), Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: StatCard('Kendaraan', '${todaySales.length}', Icons.directions_car)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StatCard('Pengeluaran', rupiah(biaya), Icons.money_off)),
            const SizedBox(width: 12),
            Expanded(child: StatCard('Laba Bersih', rupiah(omzet - biaya), Icons.account_balance_wallet)),
          ]),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onKasir,
            icon: const Icon(Icons.point_of_sale),
            label: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('BUKA KASIR', style: TextStyle(fontSize: 17)),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const StatCard(this.title, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      );
}

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  String vehicle = 'Mobil';
  final Map<String, int> prices = {
    'Motor Kecil': 15000,
    'Motor Besar': 18000,
    'Mobil': 50000,
    'Fogging': 30000,
    'Wax': 15000,
    'Foam Interior': 15000,
    'Foam Mesin': 15000,
  };
  final Set<String> extras = {};

  int get total =>
      prices[vehicle]! + extras.fold<int>(0, (sum, x) => sum + prices[x]!);

  Future<void> checkout() async {
    await store.addSale(Sale(
      vehicle: vehicle,
      services: [vehicle, ...extras],
      total: total,
      date: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() => extras.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Kasir',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          const Text('Jenis Kendaraan',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Motor Kecil', 'Motor Besar', 'Mobil'].map((x) {
              return ChoiceChip(
                label: Text('$x • ${rupiah(prices[x]!)}'),
                selected: vehicle == x,
                onSelected: (_) => setState(() => vehicle = x),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          const Text('Layanan Tambahan',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...['Fogging', 'Wax', 'Foam Interior', 'Foam Mesin'].map((x) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(x),
              subtitle: Text(rupiah(prices[x]!)),
              value: extras.contains(x),
              onChanged: (v) => setState(() {
                v == true ? extras.add(x) : extras.remove(x);
              }),
            );
          }),
          const Divider(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(rupiah(total),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: checkout,
            icon: const Icon(Icons.check),
            label: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('SIMPAN TRANSAKSI'),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Riwayat Transaksi',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (store.sales.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Belum ada transaksi'),
            )),
          ...store.sales.map((s) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.local_car_wash)),
                  title: Text(s.vehicle),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(s.date)}\n${s.services.join(', ')}',
                  ),
                  isThreeLine: true,
                  trailing: Text(rupiah(s.total),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final amount = TextEditingController();
  final note = TextEditingController();
  String category = 'Operasional';

  Future<void> save() async {
    final n = int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null || n <= 0) return;
    await store.addExpense(Expense(
      category: category,
      note: note.text.isEmpty ? category : note.text,
      amount: n,
      date: DateTime.now(),
    ));
    amount.clear();
    note.clear();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pengeluaran disimpan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Pengeluaran',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            items: ['Modal/Bahan', 'Operasional', 'Listrik', 'WiFi', 'Gaji', 'Manager', 'Lainnya']
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: (x) => setState(() => category = x!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: save, child: const Text('SIMPAN PENGELUARAN')),
          const SizedBox(height: 20),
          ...store.expenses.map((e) => Card(
                child: ListTile(
                  title: Text(e.category),
                  subtitle: Text('${e.note}\n${DateFormat('dd/MM/yyyy HH:mm').format(e.date)}'),
                  isThreeLine: true,
                  trailing: Text(rupiah(e.amount)),
                ),
              )),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sales = store.sales.where((x) => x.date.year == now.year && x.date.month == now.month);
    final expenses = store.expenses.where((x) => x.date.year == now.year && x.date.month == now.month);
    final omzet = sales.fold<int>(0, (a, b) => a + b.total);
    final biaya = expenses.fold<int>(0, (a, b) => a + b.amount);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Laporan Bulanan',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(DateFormat('MMMM yyyy', 'id_ID').format(now)),
          const SizedBox(height: 22),
          Card(child: ListTile(title: const Text('Omzet'), trailing: Text(rupiah(omzet)))),
          Card(child: ListTile(title: const Text('Total Pengeluaran'), trailing: Text(rupiah(biaya)))),
          Card(
            child: ListTile(
              title: const Text('LABA BERSIH', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(rupiah(omzet - biaya),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Jumlah transaksi: ${sales.length}'),
          Text('Jumlah kendaraan: ${sales.length}'),
        ],
      ),
    );
  }
}
