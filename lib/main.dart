import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://konlgevoddlbdxnbxltp.supabase.co',
    publishableKey: 'sb_publishable_vObTOVLHCGZz-8-pDSunvA_707UaXOs',
  );

  runApp(const EbolWashpointApp());
}

class Sale {
  final String id;
  final DateTime date;
  final String vehicle;
  final String plate;
  final int basePrice;
  final List<String> services;
  final int total;
  final String payment;

  Sale({
    required this.id,
    required this.date,
    required this.vehicle,
    required this.plate,
    required this.basePrice,
    required this.services,
    required this.total,
    required this.payment,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'vehicle': vehicle,
        'plate': plate,
        'basePrice': basePrice,
        'services': services,
        'total': total,
        'payment': payment,
      };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id'],
        date: DateTime.parse(j['date']),
        vehicle: j['vehicle'],
        plate: j['plate'],
        basePrice: j['basePrice'],
        services: List<String>.from(j['services'] ?? []),
        total: j['total'],
        payment: j['payment'] ?? 'Tunai',
      );
}

class Expense {
  final String id;
  final DateTime date;
  final String fund;
  final String category;
  final String note;
  final int amount;

  Expense({
    required this.id,
    required this.date,
    required this.fund,
    required this.category,
    required this.note,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'fund': fund,
        'category': category,
        'note': note,
        'amount': amount,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'],
        date: DateTime.parse(j['date']),
        fund: j['fund'],
        category: j['category'],
        note: j['note'] ?? '',
        amount: j['amount'],
      );
}

class EbolWashpointApp extends StatefulWidget {
  const EbolWashpointApp({super.key});

  @override
  State<EbolWashpointApp> createState() => _EbolWashpointAppState();
}

class _EbolWashpointAppState extends State<EbolWashpointApp> {
  final List<Sale> sales = [];
  final List<Expense> expenses = [];
  int tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final rawSales = p.getString('sales');
    final rawExpenses = p.getString('expenses');
    if (rawSales != null) {
      sales.addAll((jsonDecode(rawSales) as List)
          .map((e) => Sale.fromJson(Map<String, dynamic>.from(e))));
    }
    if (rawExpenses != null) {
      expenses.addAll((jsonDecode(rawExpenses) as List)
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e))));
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sales', jsonEncode(sales.map((e) => e.toJson()).toList()));
    await p.setString(
        'expenses', jsonEncode(expenses.map((e) => e.toJson()).toList()));
  }

  void addSale(Sale sale) {
    setState(() => sales.insert(0, sale));
    _save();
  }

  void addExpense(Expense expense) {
    setState(() => expenses.insert(0, expense));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(sales: sales, expenses: expenses, onOpenKasir: () => setState(() => tab = 1)),
      KasirPage(onSave: addSale),
      TransactionsPage(sales: sales),
      KasPage(sales: sales, expenses: expenses, onSaveExpense: addExpense),
      ReportPage(sales: sales, expenses: expenses),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EBOL WASHPOINT',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155EEF)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.point_of_sale_rounded), label: 'Kasir'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Transaksi'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Kas'),
            NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Laporan'),
          ],
        ),
      ),
    );
  }
}

String rupiah(int n) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(n);
}

String dateText(DateTime d) => DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d);

int sumSales(List<Sale> sales) => sales.fold(0, (a, b) => a + b.total);

int sumFundExpenses(List<Expense> e, String fund) =>
    e.where((x) => x.fund == fund).fold(0, (a, b) => a + b.amount);

class HomePage extends StatelessWidget {
  final List<Sale> sales;
  final List<Expense> expenses;
  final VoidCallback onOpenKasir;

  const HomePage({
    super.key,
    required this.sales,
    required this.expenses,
    required this.onOpenKasir,
  });

  @override
  Widget build(BuildContext context) {
    final omzet = sumSales(sales);
    final modalIn = (omzet * .30).round();
    final daruratIn = (omzet * .02).round();
    final operasionalIn = omzet - modalIn - daruratIn;

    final modalOut = sumFundExpenses(expenses, 'Kas Modal');
    final daruratOut = sumFundExpenses(expenses, 'Dana Darurat');
    final opOut = sumFundExpenses(expenses, 'Kas Operasional');

    final profit = operasionalIn - opOut;
    final kasModal = modalIn - modalOut;
    final kasDarurat = daruratIn - daruratOut;
    final kasOp = operasionalIn - opOut;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('EBOL WASHPOINT',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Dashboard',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.local_car_wash_rounded),
                )
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _heroCard(context, omzet, profit, onOpenKasir),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _moneyCard('Kas Modal', kasModal, Icons.inventory_2_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _moneyCard('Dana Darurat', kasDarurat, Icons.health_and_safety_rounded)),
                  ],
                ),
                const SizedBox(height: 10),
                _wideMoneyCard('Kas Operasional', kasOp, Icons.account_balance_wallet_rounded),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Alokasi Omzet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                _allocationRow('Kas Modal', modalIn, '30%'),
                _allocationRow('Dana Darurat', daruratIn, '2%'),
                _allocationRow('Kas Operasional', operasionalIn, '68%'),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Ringkasan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                _summaryTile('Transaksi', '${sales.length}', Icons.receipt_long_rounded),
                _summaryTile('Pengeluaran', rupiah(expenses.fold(0, (a, b) => a + b.amount)),
                    Icons.payments_outlined),
                _summaryTile('Profit Bersih', rupiah(profit), Icons.trending_up_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context, int omzet, int profit, VoidCallback open) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF155EEF), Color(0xFF4F7CFF)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OMZET', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(rupiah(omzet),
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Profit bersih\n${rupiah(profit)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF155EEF)),
                onPressed: open,
                icon: const Icon(Icons.add),
                label: const Text('Kasir'),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _moneyCard(String title, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 24),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(rupiah(value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _wideMoneyCard(String title, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        CircleAvatar(child: Icon(icon)),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
        Text(rupiah(value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _allocationRow(String name, int value, String pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(pct, style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 16),
          Text(rupiah(value), style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _summaryTile(String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon, size: 20)),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class KasirPage extends StatefulWidget {
  final ValueChanged<Sale> onSave;
  const KasirPage({super.key, required this.onSave});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  String vehicle = 'Mobil';
  String payment = 'Tunai';
  final plate = TextEditingController();
  final selected = <String>{};

  final vehiclePrices = {
    'Motor Kecil': 15000,
    'Motor Besar': 18000,
    'Mobil': 50000,
  };

  final servicePrices = {
    'Fogging': 30000,
    'Wax': 15000,
    'Foam Interior': 15000,
    'Foam Mesin': 15000,
  };

  int get total =>
      (vehiclePrices[vehicle] ?? 0) +
      selected.fold(0, (sum, name) => sum + (servicePrices[name] ?? 0));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        const Text('Kasir', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Catat kendaraan dan pembayaran'),
        const SizedBox(height: 22),
        TextField(
          controller: plate,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Nomor Polisi (Nopol)',
            hintText: 'Contoh: E 1234 AB',
            prefixIcon: const Icon(Icons.directions_car_filled_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Jenis Kendaraan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...vehiclePrices.keys.map((v) => _vehicleButton(v)),
        const SizedBox(height: 15),
        const Text('Layanan Tambahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...servicePrices.keys.map((s) => CheckboxListTile(
              value: selected.contains(s),
              onChanged: (v) => setState(() => v == true ? selected.add(s) : selected.remove(s)),
              title: Text(s),
              subtitle: Text(rupiah(servicePrices[s]!)),
              secondary: Icon(_serviceIcon(s)),
              contentPadding: EdgeInsets.zero,
            )),
        const SizedBox(height: 12),
        const Text('Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Tunai', label: Text('Tunai'), icon: Icon(Icons.payments)),
            ButtonSegment(value: 'QRIS', label: Text('QRIS'), icon: Icon(Icons.qr_code_2)),
            ButtonSegment(value: 'Transfer', label: Text('Transfer'), icon: Icon(Icons.account_balance)),
          ],
          selected: {payment},
          onSelectionChanged: (v) => setState(() => payment = v.first),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Expanded(child: Text('TOTAL', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
              Text(rupiah(total), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: _save,
          icon: const Icon(Icons.check_circle),
          label: const Text('Simpan Transaksi'),
        ),
      ],
    );
  }

  Widget _vehicleButton(String v) {
    final active = vehicle == v;
    final icon = v == 'Mobil'
        ? Icons.directions_car_filled_rounded
        : Icons.two_wheeler_rounded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(15),
          backgroundColor: active ? const Color(0xFFE7EFFF) : Colors.white,
          side: BorderSide(color: active ? const Color(0xFF155EEF) : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () => setState(() => vehicle = v),
        child: Row(children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(rupiah(vehiclePrices[v]!)),
          if (active) const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(Icons.check_circle),
          )
        ]),
      ),
    );
  }

  IconData _serviceIcon(String s) {
    if (s == 'Fogging') return Icons.air;
    if (s == 'Wax') return Icons.auto_awesome;
    if (s == 'Foam Interior') return Icons.airline_seat_recline_normal;
    return Icons.settings;
  }

  void _save() {
    if (plate.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nopol wajib diisi.')),
      );
      return;
    }
    widget.onSave(Sale(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      vehicle: vehicle,
      plate: plate.text.trim().toUpperCase(),
      basePrice: vehiclePrices[vehicle]!,
      services: selected.toList(),
      total: total,
      payment: payment,
    ));
    plate.clear();
    setState(() {
      selected.clear();
      vehicle = 'Mobil';
      payment = 'Tunai';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan.')),
    );
  }
}

class TransactionsPage extends StatelessWidget {
  final List<Sale> sales;
  const TransactionsPage({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Transaksi', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('${sales.length} transaksi tersimpan'),
        const SizedBox(height: 16),
        if (sales.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: Text('Belum ada transaksi.')),
          ),
        ...sales.map((s) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(s.vehicle == 'Mobil'
                      ? Icons.directions_car_filled
                      : Icons.two_wheeler),
                ),
                title: Text('${s.vehicle} • ${s.plate}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${dateText(s.date)} • ${s.payment}\n'
                    '${s.services.isEmpty ? 'Cuci standar' : s.services.join(', ')}'),
                isThreeLine: true,
                trailing: Text(rupiah(s.total),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            )),
      ],
    );
  }
}

class KasPage extends StatefulWidget {
  final List<Sale> sales;
  final List<Expense> expenses;
  final ValueChanged<Expense> onSaveExpense;

  const KasPage({
    super.key,
    required this.sales,
    required this.expenses,
    required this.onSaveExpense,
  });

  @override
  State<KasPage> createState() => _KasPageState();
}

class _KasPageState extends State<KasPage> {
  String fund = 'Kas Operasional';
  String category = 'UM (Uang Makan)';
  final note = TextEditingController();
  final amount = TextEditingController();

  final categories = {
    'Kas Operasional': ['UM (Uang Makan)', 'Gaji Karyawan', 'BON Karyawan', 'Lainnya'],
    'Kas Modal': ['Shampo', 'Semir', 'Listrik', 'WiFi', 'Bahan Lainnya', 'Peralatan'],
    'Dana Darurat': ['Kebutuhan Darurat', 'Perbaikan Mendesak', 'Lainnya'],
  };

  @override
  Widget build(BuildContext context) {
    final omzet = sumSales(widget.sales);
    final modalIn = (omzet * .30).round();
    final daruratIn = (omzet * .02).round();
    final opIn = omzet - modalIn - daruratIn;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text('Kas & Pengeluaran', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _balance('Kas Modal', modalIn - sumFundExpenses(widget.expenses, 'Kas Modal'))),
            const SizedBox(width: 8),
            Expanded(child: _balance('Darurat', daruratIn - sumFundExpenses(widget.expenses, 'Dana Darurat'))),
          ],
        ),
        const SizedBox(height: 8),
        _balance('Kas Operasional', opIn - sumFundExpenses(widget.expenses, 'Kas Operasional')),
        const SizedBox(height: 24),
        const Text('Input Pengeluaran', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: fund,
          decoration: const InputDecoration(labelText: 'Sumber Kas', border: OutlineInputBorder()),
          items: categories.keys.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (v) => setState(() {
            fund = v!;
            category = categories[fund]!.first;
          }),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(labelText: 'Kategori Pengeluaran', border: OutlineInputBorder()),
          items: categories[fund]!.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (v) => setState(() => category = v!),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: note,
          decoration: const InputDecoration(labelText: 'Keterangan / Nama', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
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
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Simpan Pengeluaran'),
        ),
        const SizedBox(height: 22),
        const Text('Riwayat Pengeluaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...widget.expenses.take(20).map((e) => Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: Text('${e.category} • ${e.fund}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${e.note.isEmpty ? '-' : e.note} • ${dateText(e.date)}'),
                trailing: Text(rupiah(e.amount),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            )),
      ],
    );
  }

  Widget _balance(String title, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(rupiah(value), style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _save() {
    final n = int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (n <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal belum benar.')),
      );
      return;
    }
    widget.onSaveExpense(Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      fund: fund,
      category: category,
      note: note.text.trim(),
      amount: n,
    ));
    note.clear();
    amount.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengeluaran tersimpan.')),
    );
  }
}

class ReportPage extends StatelessWidget {
  final List<Sale> sales;
  final List<Expense> expenses;

  const ReportPage({super.key, required this.sales, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final omzet = sumSales(sales);
    final modalIn = (omzet * .30).round();
    final daruratIn = (omzet * .02).round();
    final opIn = omzet - modalIn - daruratIn;

    final modalOut = sumFundExpenses(expenses, 'Kas Modal');
    final daruratOut = sumFundExpenses(expenses, 'Dana Darurat');
    final opOut = sumFundExpenses(expenses, 'Kas Operasional');

    final profit = opIn - opOut;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text('Laporan', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())),
        const SizedBox(height: 18),
        _section('Omzet', [
          ['Total Omzet', omzet],
          ['Kas Modal 30%', modalIn],
          ['Dana Darurat 2%', daruratIn],
          ['Kas Operasional 68%', opIn],
        ]),
        _section('Kas Modal', [
          ['Pemasukan', modalIn],
          ['Pengeluaran', modalOut],
          ['Saldo', modalIn - modalOut],
        ]),
        _section('Dana Darurat', [
          ['Pemasukan', daruratIn],
          ['Pengeluaran', daruratOut],
          ['Saldo', daruratIn - daruratOut],
        ]),
        _section('Kas Operasional', [
          ['Pemasukan', opIn],
          ['Pengeluaran', opOut],
          ['Saldo / Profit Bersih', profit],
        ]),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PROFIT BERSIH',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text(rupiah(profit),
                  style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              const Text('Kas Operasional 68% - Pengeluaran Operasional',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<List<dynamic>> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const Divider(height: 20),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Expanded(child: Text(r[0] as String)),
                    Text(rupiah(r[1] as int),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
