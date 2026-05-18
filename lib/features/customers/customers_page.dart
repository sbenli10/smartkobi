import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_detail_page.dart';

class CustomerModel {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final DateTime? lastInteractionAt;

  CustomerModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.lastInteractionAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      businessId: json['business_id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      lastInteractionAt: json['last_interaction_at'] != null
          ? DateTime.parse(json['last_interaction_at'])
          : null,
    );
  }
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _supabase = Supabase.instance.client;

  List<CustomerModel> _customers = [];
  bool _loading = true;
  String _searchQuery = "";

  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<String?> _getBusinessId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

   final res = await _supabase
    .from('user_business_roles')
    .select('business_id')
    .eq('user_id', user.id)
    .limit(1)
    .maybeSingle();

    return res?['business_id'];

  }

  Future<void> _loadCustomers() async {
    try {
      final businessId = await _getBusinessId();
      if (businessId == null) return;

      final data = await _supabase
          .from('customers')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      setState(() {
        _customers =
            (data as List).map((e) => CustomerModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<CustomerModel> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _openAddCustomerSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Yeni Müşteri",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Müşteri Adı",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Telefon",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "E-posta",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;

                    final businessId = await _getBusinessId();
                    if (businessId == null) return;

                    await _supabase.from('customers').insert({
                      'business_id': businessId,
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'email': emailController.text,
                      'last_interaction_at':
                          DateTime.now().toIso8601String(),
                    });

                    Navigator.pop(context);
                    _loadCustomers();
                  },
                  child: const Text("Kaydet"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Müşteri Yönetimi"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Müşteri Ara",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: customers.isEmpty
                        ? const Center(
                            child: Text(
                                "Henüz müşteri yok. + butonuna basarak ekleyin."),
                          )
                        : SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text("Ad")),
                                DataColumn(label: Text("Telefon")),
                                DataColumn(label: Text("E-posta")),
                                DataColumn(label: Text("Son Etkileşim")),
                              ],
                              rows: customers.map((c) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(c.name),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CustomerDetailPage(customer: c),
                                          ),
                                        );
                                      },
                                    ),
                                    DataCell(Text(c.phone ?? "-")),
                                    DataCell(Text(c.email ?? "-")),
                                    DataCell(Text(
                                      c.lastInteractionAt == null
                                          ? "-"
                                          : _dateFormat.format(c.lastInteractionAt!),
                                    )),
                                  ],
                                );
                              }).toList(),

                            ),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "customersFab",
        onPressed: _openAddCustomerSheet,
        icon: const Icon(Icons.person_add),
        label: const Text("Yeni Müşteri"),
      ),
    );
  }
}
