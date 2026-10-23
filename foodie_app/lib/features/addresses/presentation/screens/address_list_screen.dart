import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/address_provider.dart';
import 'add_edit_address_screen.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressListNotifierProvider);
    final notifier = ref.read(addressListNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
      ),
      body: _buildBody(context, ref, state, notifier, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditAddressScreen(),
            ),
          );
          notifier.loadAddresses();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add New Address'),
      ),

    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AddressListState state,
    AddressListNotifier notifier,
    ThemeData theme,
  ) {
    if (state.isLoading && state.addresses.isEmpty) {
      return const LoadingIndicator(message: 'Fetching saved addresses...');
    }

    if (state.errorMessage != null && state.addresses.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: notifier.loadAddresses,
      );
    }

    if (state.addresses.isEmpty) {
      return EmptyView(
        title: 'No addresses saved',
        message: 'Add a delivery address to place food orders.',
        icon: Icons.location_off_outlined,
        action: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditAddressScreen(),
              ),
            );
          },
          child: const Text('Add Address'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.loadAddresses,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        itemCount: state.addresses.length,
        itemBuilder: (context, index) {
          final address = state.addresses[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: address.isDefault
                  ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            address.label.toLowerCase() == 'home'
                                ? Icons.home
                                : address.label.toLowerCase() == 'work'
                                    ? Icons.work
                                    : Icons.location_on,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            address.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditAddressScreen(address: address),
                              ),
                            );
                            notifier.loadAddresses();
                          } else if (value == 'default') {
                            await notifier.setDefaultAddress(address.id);
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete Address?'),
                                content: Text(
                                    'Are you sure you want to delete "${address.label}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('CANCEL'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);
                                      final deleted = await notifier.deleteAddress(address.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(deleted
                                                ? 'Address deleted successfully'
                                                : 'Failed to delete address'),
                                            backgroundColor: deleted
                                                ? Colors.green.shade700
                                                : theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('DELETE'),
                                  ),
                                ],
                              ),
                            );
                          }

                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          if (!address.isDefault)
                            const PopupMenuItem(
                              value: 'default',
                              child: Text('Set as Default'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${address.line1}${address.line2 != null && address.line2!.isNotEmpty ? ', ${address.line2}' : ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.city} - ${address.pincode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
