import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/presentation/providers/address_provider.dart';
import '../../../addresses/presentation/screens/add_edit_address_screen.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/checkout_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  Address? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final addressState = ref.watch(addressListNotifierProvider);
    final checkoutState = ref.watch(checkoutNotifierProvider);
    final checkoutNotifier = ref.read(checkoutNotifierProvider.notifier);
    final theme = Theme.of(context);

    // Ensure selected address is valid and synced with latest addressState
    if (addressState.addresses.isNotEmpty) {
      if (_selectedAddress == null ||
          !addressState.addresses.any((a) => a.id == _selectedAddress!.id)) {
        _selectedAddress = addressState.defaultAddress ?? addressState.addresses.first;
      } else {
        _selectedAddress = addressState.addresses.firstWhere(
          (a) => a.id == _selectedAddress!.id,
          orElse: () => _selectedAddress!,
        );
      }
    } else {
      _selectedAddress = null;
    }

    ref.listen<CheckoutState>(checkoutNotifierProvider, (previous, next) {
      if (next.status == CheckoutStatus.success && next.verifiedOrder != null) {
        // Open tracking screen upon verified successful payment
        context.go('/tracking/${next.verifiedOrder!.id}');
      }
    });

    if (cartState.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: Text('Your cart is empty.'),
        ),
      );
    }

    final restaurant = cartState.restaurant!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm & Pay'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner if any
            if (checkoutState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        checkoutState.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Delivery Address Section
            Text(
              'Delivery Address',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (addressState.isLoading && addressState.addresses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (addressState.errorMessage != null && addressState.addresses.isEmpty)
              Card(
                elevation: 1,
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Failed to load saved addresses: ${addressState.errorMessage}',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.read(addressListNotifierProvider.notifier).loadAddresses();
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final newAddress = await Navigator.push<Address?>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddEditAddressScreen(),
                                ),
                              );
                              if (newAddress != null) {
                                setState(() => _selectedAddress = newAddress);
                                await ref.read(addressListNotifierProvider.notifier).loadAddresses();
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Address'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else if (addressState.addresses.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'No saved delivery addresses found.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newAddress = await Navigator.push<Address?>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEditAddressScreen(),
                            ),
                          );
                          if (newAddress != null) {
                            setState(() => _selectedAddress = newAddress);
                            await ref.read(addressListNotifierProvider.notifier).loadAddresses();
                          }
                        },
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('Add Delivery Address'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _selectedAddress?.label ?? 'Select Address',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddressSelectionModal(
                              context,
                              addressState.addresses,
                            ),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('CHANGE'),
                          ),
                        ],
                      ),
                      if (_selectedAddress != null) ...[
                        const SizedBox(height: 4),
                        Text(_selectedAddress!.line1),
                        if (_selectedAddress!.line2 != null &&
                            _selectedAddress!.line2!.isNotEmpty)
                          Text(_selectedAddress!.line2!),
                        Text(
                            '${_selectedAddress!.city} - ${_selectedAddress!.pincode}'),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),


            // Restaurant & Order Summary
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...cartState.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.quantity}x  ${item.menuItem.name}'),
                            Text(CurrencyFormatter.formatPaise(
                                item.subtotalPaise)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Item Subtotal'),
                        Text(CurrencyFormatter.formatPaise(
                            cartState.subtotalPaise)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text(cartState.deliveryFeePaise == 0
                            ? 'FREE'
                            : CurrencyFormatter.formatPaise(
                                cartState.deliveryFeePaise)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Taxes & Charges (5%)'),
                        Text(CurrencyFormatter.formatPaise(cartState.taxPaise)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total to Pay',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(cartState.totalPaise),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: (_selectedAddress == null || checkoutState.isSubmitting)
                ? null
                : () {
                    if (checkoutState.status == CheckoutStatus.paymentFailed) {
                      checkoutNotifier.retryPaymentForCreatedOrder();
                    } else {
                      checkoutNotifier.placeOrderAndPay(
                        addressId: _selectedAddress!.id,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: checkoutState.isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getProcessingMessage(checkoutState.status),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Text(
                    _selectedAddress == null
                        ? 'Select Delivery Address to Place Order'
                        : (checkoutState.status == CheckoutStatus.paymentFailed
                            ? 'Retry Payment - ${CurrencyFormatter.formatPaise(cartState.totalPaise)}'
                            : 'Place Order - ${CurrencyFormatter.formatPaise(cartState.totalPaise)}'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),

          ),
        ),
      ),
    );
  }

  String _getProcessingMessage(CheckoutStatus status) {
    switch (status) {
      case CheckoutStatus.submittingOrder:
        return 'Creating order...';
      case CheckoutStatus.processingPayment:
        return 'Processing payment...';
      case CheckoutStatus.verifyingPayment:
        return 'Verifying payment...';
      default:
        return 'Please wait...';
    }
  }

  void _showAddressSelectionModal(
    BuildContext context,
    List<Address> addresses,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        final theme = Theme.of(modalContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...addresses.map((addr) {
                    final isSelected = _selectedAddress?.id == addr.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(addr.label,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${addr.line1}, ${addr.city} - ${addr.pincode}'),
                      onTap: () {
                        setState(() => _selectedAddress = addr);
                        Navigator.pop(modalContext);
                      },
                    );
                  }),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Add New Delivery Address',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      Navigator.pop(modalContext);
                      final newAddress = await Navigator.push<Address?>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditAddressScreen(),
                        ),
                      );
                      if (newAddress != null) {
                        setState(() => _selectedAddress = newAddress);
                        await ref.read(addressListNotifierProvider.notifier).loadAddresses();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

