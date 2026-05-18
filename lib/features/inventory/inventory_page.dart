import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_history_page.dart';
import 'barcode_scanner_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

class ProductModel {
  final String id;
  final String businessId;
  final String name;
  final String sku;
  final String unit;
  final double price;
  final double minStock;
  double stock;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.sku,
    required this.unit,
    required this.price,
    required this.minStock,
    required this.stock,
  });

  bool get isCritical => stock <= minStock;
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _supabase = Supabase.instance.client;
  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final Set<String> _selectedIds = {};
  List<ProductModel> _products = [];
  bool _loading = true;
  String _searchQuery = "";

 @override
  void initState() {
    super.initState();
    _subscribeRealtime();
    _loadProducts();
  }

late RealtimeChannel _channel;

void _subscribeRealtime() {
  _channel = _supabase.channel('inventory_channel')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'inventory_movements',
      callback: (_) => _loadProducts(),
    )
    ..subscribe();
}

@override
void dispose() {
  _supabase.removeChannel(_channel);
  super.dispose();
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

  Future<void> _loadProducts() async {
  final businessId = await _getBusinessId();
  if (businessId == null) return;

  final data = await _supabase
    .from('product_stocks')
    .select()
    .eq('business_id', businessId);

  setState(() {
    _products = (data as List)
        .map((p) => ProductModel(
              id: p['id'],
              businessId: p['business_id'],
              name: p['name'],
              sku: p['sku'],
              unit: p['unit'],
              price: (p['price'] as num).toDouble(),
              minStock:
                  (p['min_stock'] as num).toDouble(),
              stock:
                  (p['stock'] as num).toDouble(),
            ))
        .toList();

    _loading = false;
  });
}

Future<void> _deleteProducts(List<String> ids) async {
  await _supabase
      .from('products')
      .update({'deleted_at': DateTime.now().toIso8601String()})
      .inFilter('id', ids);


  _loadProducts();
}

Future<void> _importProducts() async {
  final businessId = await _getBusinessId();
  if (businessId == null) return;

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result == null) return;

  if (result.files.single.bytes == null) return;

  final bytes = result.files.single.bytes!;
  final csvString = utf8.decode(bytes);
  final rows = CsvToListConverter().convert(csvString);

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];

    await _supabase.from('products').insert({
      'business_id': businessId,
      'name': row[0],
      'sku': row[1],
      'unit': row[2],
      'price': double.parse(row[3].toString()),
      'min_stock': double.parse(row[4].toString()),
    });
  }

  _loadProducts();
}

  Future<void> _addMovement(ProductModel product, double qty) async {
  final businessId = await _getBusinessId();
  if (businessId == null) return;

  await _supabase.from('inventory_movements').insert({
    'business_id': businessId,
    'product_id': product.id,
    'quantity': qty,
    'reason': 'adjustment', // ENUM'a uygun
    'occurred_at': DateTime.now().toIso8601String(),
  });

  await _loadProducts();
}

  void _openAddProductSheet() {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final skuController = TextEditingController();
  final unitController = TextEditingController(text: "adet");
  final priceController = TextEditingController();
  final minStockController = TextEditingController();
  final initialStockController = TextEditingController(text: "0");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Yeni Ürün",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                /// Ürün Adı
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Ürün Adı",
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Zorunlu alan" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: skuController,
                  decoration: InputDecoration(
                    labelText: "SKU",
                    prefixIcon: const Icon(Icons.qr_code),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final scannedCode = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BarcodeScannerPage(),
                          ),
                        );

                        if (scannedCode != null) {
                          skuController.text = scannedCode;
                        }
                      },
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "SKU zorunludur" : null,
                ),

                const SizedBox(height: 16),

                /// Birim
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: "Birim (adet, kg, lt vs)",
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Birim zorunlu" : null,
                ),
                const SizedBox(height: 16),

                /// Fiyat
                TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Satış Fiyatı",
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Zorunlu alan";
                    if (double.tryParse(v) == null) return "Geçerli sayı girin";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Minimum stok
                TextFormField(
                  controller: minStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Minimum Stok",
                    prefixIcon: Icon(Icons.warning),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Zorunlu alan";
                    if (double.tryParse(v) == null) return "Geçerli sayı girin";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Başlangıç Stok
                TextFormField(
                  controller: initialStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Başlangıç Stok",
                    prefixIcon: Icon(Icons.add_box),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Zorunlu alan";
                    if (double.tryParse(v) == null) return "Geçerli sayı girin";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Kaydet"),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      try {
                        final businessId = await _getBusinessId();

                        if (businessId == null) {
                          throw Exception("Business ID bulunamadı");
                        }

                        final price =
                            double.parse(priceController.text.trim());
                        final minStock =
                            double.parse(minStockController.text.trim());
                        final initialStock =
                            double.parse(initialStockController.text.trim());

                        /// 1️⃣ ÜRÜN EKLE
                        final inserted = await _supabase
                            .from('products')
                            .insert({
                              'business_id': businessId,
                              'name': nameController.text.trim(),
                              'sku': skuController.text.trim(),
                              'unit': unitController.text.trim(),
                              'price': price,
                              'min_stock': minStock,
                            })
                            .select()
                            .single();

                        /// 2️⃣ BAŞLANGIÇ STOK VARSA MOVEMENT EKLE
                        if (initialStock > 0) {
                          await _supabase.from('inventory_movements').insert({
                            'business_id': businessId,
                            'product_id': inserted['id'],
                            'quantity': initialStock,
                            'reason': 'purchase', // ENUM'a uygun
                            'occurred_at': DateTime.now().toIso8601String(),
                          });
                        }


                        if (mounted) {
                          Navigator.pop(context);
                          _loadProducts();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Ürün başarıyla eklendi"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Hata oluştu: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _products
        : _products
            .where((p) => p.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    Widget _criticalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "KRİTİK",
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


   return Scaffold(
  appBar: AppBar(
    title: const Text("Stok Takibi"),
    actions: [
      if (_selectedIds.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            await _deleteProducts(_selectedIds.toList());
            setState(() => _selectedIds.clear());
          },
        ),
      IconButton(
        icon: const Icon(Icons.upload_file),
        onPressed: _importProducts,
      ),
    ],
  ),
  body: _loading
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Ürün Ara",
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text("Henüz ürün yok."),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text("Ürün")),
                            DataColumn(label: Text("SKU")),
                            DataColumn(label: Text("Birim")),
                            DataColumn(label: Text("Fiyat")),
                            DataColumn(label: Text("Stok")),
                            DataColumn(label: Text("Min")),
                            DataColumn(label: Text("Durum")),
                            DataColumn(label: Text("İşlem")),
                          ],
                          rows: filtered.map((p) {
                            return DataRow(
                              selected: _selectedIds.contains(p.id),
                              onSelectChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedIds.add(p.id);
                                  } else {
                                    _selectedIds.remove(p.id);
                                  }
                                });
                              },
                              cells: [

                                /// Ürün adı
                                DataCell(
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        child: Text(
                                          p.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (p.isCritical) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            "KRİTİK",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                /// SKU
                                DataCell(Text(p.sku)),

                                /// Birim
                                DataCell(Text(p.unit)),

                                /// Fiyat
                                DataCell(
                                  Text(_currency.format(p.price)),
                                ),

                                /// Stok
                                DataCell(
                                  Text(
                                    p.stock.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: p.isCritical
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ),

                                /// Min stok
                                DataCell(
                                  Text(p.minStock.toStringAsFixed(0)),
                                ),

                                /// Durum
                                DataCell(
                                  Text(
                                    p.isCritical ? "Kritik" : "Normal",
                                    style: TextStyle(
                                      color: p.isCritical
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                /// İşlem butonları
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _addMovement(p, -1),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _addMovement(p, 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.history,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  InventoryHistoryPage(
                                                      product: p),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
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
    heroTag: "inventoryFab",
    onPressed: _openAddProductSheet,
    icon: const Icon(Icons.add_box),
    label: const Text("Yeni Ürün"),
  ),
);


  }
}
