import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Supabase.initialize(
    url: 'https://konlgevoddlbdxnbxltp.supabase.co',
    publishableKey: 'sb_publishable_vObTOVLHCGZz-8-pDSunvA_707UaXOs',
  );

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  final androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImplementation?.requestNotificationsPermission();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    ),
  );
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

class WashQueueItem {
  final String id;
  final String plate;
  final String vehicle;
  final List<String> services;
  final int total;
  final DateTime createdAt;
  final DateTime dueAt;
  final String status;

  const WashQueueItem({
    required this.id,
    required this.plate,
    required this.vehicle,
    required this.services,
    required this.total,
    required this.createdAt,
    required this.dueAt,
    required this.status,
  });

  String get statusText {
    switch (status) {
      case 'paid':
        return 'Sudah dibayar';
      case 'processing':
        return 'Sedang dicuci';
      default:
        return 'Menunggu pembayaran';
    }
  }

  WashQueueItem copyWith({
    String? id,
    String? plate,
    String? vehicle,
    List<String>? services,
    int? total,
    DateTime? createdAt,
    DateTime? dueAt,
    String? status,
  }) {
    return WashQueueItem(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      vehicle: vehicle ?? this.vehicle,
      services: services ?? this.services,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plate': plate,
        'vehicle': vehicle,
        'services': services,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
        'dueAt': dueAt.toIso8601String(),
        'status': status,
      };

  factory WashQueueItem.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now();
    final dueAt = DateTime.tryParse(json['dueAt'] ?? '') ??
        createdAt.add(const Duration(minutes: 60));

    return WashQueueItem(
      id: json['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      plate: json['plate'] ?? '-',
      vehicle: json['vehicle'] ?? 'Mobil',
      services: List<String>.from(json['services'] ?? []),
      total: (json['total'] ?? 0) as int,
      createdAt: createdAt,
      dueAt: dueAt,
      status: json['status'] ?? 'waiting',
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const EbolWashpointApp(),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Login gagal. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_car_wash,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EBOL WASHPOINT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Login Admin / Kasir'),
                  const SizedBox(height: 24),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('LOGIN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EbolWashpointApp extends StatefulWidget {
  const EbolWashpointApp({super.key});

  @override
  State<EbolWashpointApp> createState() => _EbolWashpointAppState();
}

class _EbolWashpointAppState extends State<EbolWashpointApp> {
  final List<Sale> sales = [];
  final List<Expense> expenses = [];
  final List<WashQueueItem> queueItems = [];
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
    final rawQueue = p.getString('queueItems');

    if (rawSales != null) {
      sales.addAll((jsonDecode(rawSales) as List)
          .map((e) => Sale.fromJson(Map<String, dynamic>.from(e))));
    }

    if (rawExpenses != null) {
      expenses.addAll((jsonDecode(rawExpenses) as List)
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e))));
    }

    if (rawQueue != null) {
      final parsed = (jsonDecode(rawQueue) as List)
          .map((e) => WashQueueItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      queueItems.addAll(parsed);

      for (final item in queueItems) {
        if (item.status == 'waiting' && item.dueAt.isAfter(DateTime.now())) {
          await _schedulePaymentReminder(item);
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sales', jsonEncode(sales.map((e) => e.toJson()).toList()));
    await p.setString(
        'expenses', jsonEncode(expenses.map((e) => e.toJson()).toList()));
    await p.setString(
        'queueItems', jsonEncode(queueItems.map((e) => e.toJson()).toList()));
  }

  void addSale(Sale sale) {
    setState(() => sales.insert(0, sale));
    _save();
  }

  void addExpense(Expense expense) {
    setState(() => expenses.insert(0, expense));
    _save();
  }

  void addQueueItem(WashQueueItem item) {
    setState(() => queueItems.insert(0, item));
    _schedulePaymentReminder(item);
    _save();
  }

void markQueuePaid(String queueId) {
  final index = queueItems.indexWhere((item) => item.id == queueId);

  if (index < 0) return;

  final item = queueItems[index];

  int basePrice = 0;

  if (item.vehicle == 'Mobil') {
    basePrice = 50000;
  } else if (item.vehicle == 'Motor Besar') {
    basePrice = 18000;
  } else if (item.vehicle == 'Motor Kecil') {
    basePrice = 15000;
  }

  final sale = Sale(
    id: item.id,
    date: DateTime.now(),
    vehicle: item.vehicle,
    plate: item.plate,
    basePrice: basePrice,
    services: item.services,
    total: item.total,
    payment: 'Tunai',
  );

  setState(() {
    queueItems[index] = item.copyWith(status: 'completed');
    sales.insert(0, sale);
  });

  _save();
}

  Future<void> _schedulePaymentReminder(WashQueueItem item) async {
    final now = DateTime.now();
    if (!item.dueAt.isAfter(now)) {
      return;
    }

    final scheduledAt = tz.TZDateTime.from(item.dueAt, tz.local);
    final title = 'Pembayaran mobil ${item.plate}';
    final body = 'Mobil ${item.plate} sudah masuk antrian ${item.vehicle} dan menunggu pembayaran sejak 60 menit yang lalu.';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      int.tryParse(item.id) ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      scheduledAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'washpoint_payment_reminder',
          'Pembayaran Cuci',
          channelDescription: 'Pengingat pembayaran kendaraan yang masuk antrian',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        sales: sales,
        expenses: expenses,
        onOpenKasir: () => setState(() => tab = 1),
      ),
      KasirPage(
        onSave: addSale,
        onQueue: addQueueItem,
      ),
      TransactionsPage(sales: sales),
      AntrianPage(
        queueItems: queueItems,
        onMarkPaid: markQueuePaid,
      ),
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
            NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: 'Antrian'),
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
  final ValueChanged<WashQueueItem> onQueue;

  const KasirPage({
    super.key,
    required this.onSave,
    required this.onQueue,
  });

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

    final now = DateTime.now();
    final queueId = now.microsecondsSinceEpoch.toString();
    final plateText = plate.text.trim().toUpperCase();

    final sale = Sale(
      id: queueId,
      date: now,
      vehicle: vehicle,
      plate: plateText,
      basePrice: vehiclePrices[vehicle]!,
      services: selected.toList(),
      total: total,
      payment: payment,
    );

    final queueItem = WashQueueItem(
      id: queueId,
      plate: plateText,
      vehicle: vehicle,
      services: selected.toList(),
      total: total,
      createdAt: now,
      dueAt: now.add(const Duration(minutes: 60)),
      status: 'waiting',
    );

    
    widget.onQueue(queueItem);

    plate.clear();
    setState(() {
      selected.clear();
      vehicle = 'Mobil';
      payment = 'Tunai';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi dan antrian berhasil disimpan.')),
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

class AntrianPage extends StatelessWidget {
  final List<WashQueueItem> queueItems;
  final ValueChanged<String> onMarkPaid;

  const AntrianPage({
    super.key,
    required this.queueItems,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Antrian Cuci', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('${queueItems.length} kendaraan menunggu'),
        const SizedBox(height: 16),
        if (queueItems.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: Text('Belum ada mobil di antrian.')),
          ),
        ...queueItems.map((item) {
          final isLate = item.dueAt.isBefore(DateTime.now()) || item.dueAt.isAtSameMomentAs(DateTime.now());
          final isPaid = item.status == 'paid';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.vehicle} • ${item.plate}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPaid ? Colors.green.shade100 : (isLate ? Colors.orange.shade100 : Colors.blue.shade100),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isPaid ? 'Sudah dibayar' : (isLate ? 'Menunggu bayar' : 'Antrian'),
                          style: TextStyle(
                            color: isPaid ? Colors.green.shade900 : (isLate ? Colors.orange.shade900 : Colors.blue.shade900),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Layanan: ${item.services.isEmpty ? 'Cuci standar' : item.services.join(', ')}'),
                  const SizedBox(height: 4),
                  Text('Waktu masuk: ${dateText(item.createdAt)}'),
                  Text('Reminder pembayaran: ${dateText(item.dueAt)}'),
                  if (!isPaid) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => onMarkPaid(item.id),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Tandai Sudah Bayar'),
                    )
                  ]
                ],
              ),
            ),
          );
        }),
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

