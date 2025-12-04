import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/neo_theme.dart';
import '../../core/widgets/neo_widgets.dart';
import 'customer_model.dart';
import 'customer_service.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const CustomerListScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customers = ref.watch(customerServiceProvider);

    final filteredCustomers = customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? NeoColors.darkBackground : NeoColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Customer' : 'Customers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : NeoColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: NeoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search,
                      color: isDark ? Colors.white54 : NeoColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),

          // List
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Text(
                      'No customers found',
                      style: TextStyle(
                        color:
                            isDark ? Colors.white54 : NeoColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCustomerCard(isDark, customer),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerDialog(context, null),
        backgroundColor: NeoColors.primaryGradient[0],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerCard(bool isDark, Customer customer) {
    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          Navigator.pop(context, customer);
        } else {
          _showCustomerDialog(context, customer);
        }
      },
      child: NeoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: NeoColors.blueGradient
                      .map((c) => c.withValues(alpha: 0.2))
                      .toList(),
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NeoColors.blueGradient[0],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : NeoColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone,
                          size: 14,
                          color: isDark
                              ? Colors.white54
                              : NeoColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? Colors.white54 : NeoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!widget.isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, customer),
              ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, Customer? customer) {
    final nameController = TextEditingController(text: customer?.name);
    final phoneController = TextEditingController(text: customer?.phone);
    final emailController = TextEditingController(text: customer?.email);
    final addressController = TextEditingController(text: customer?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration:
                    const InputDecoration(labelText: 'Email (Optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: addressController,
                decoration:
                    const InputDecoration(labelText: 'Address (Optional)'),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                return;
              }

              final newCustomer = Customer(
                id: customer?.id,
                name: nameController.text,
                phone: phoneController.text,
                email: emailController.text,
                address: addressController.text,
                createdAt: customer?.createdAt,
              );

              if (customer == null) {
                ref
                    .read(customerServiceProvider.notifier)
                    .addCustomer(newCustomer);
              } else {
                ref
                    .read(customerServiceProvider.notifier)
                    .updateCustomer(newCustomer);
              }

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(customerServiceProvider.notifier)
                  .deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
