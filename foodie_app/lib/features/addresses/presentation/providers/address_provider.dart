import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/address_remote_data_source.dart';
import '../../data/repositories/address_repository_impl.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final remoteDataSource = AddressRemoteDataSource(dio);
  return AddressRepositoryImpl(remoteDataSource);
});

class AddressListState {
  final List<Address> addresses;
  final bool isLoading;
  final String? errorMessage;

  const AddressListState({
    required this.addresses,
    required this.isLoading,
    this.errorMessage,
  });

  factory AddressListState.initial() => const AddressListState(
        addresses: [],
        isLoading: true,
        errorMessage: null,
      );

  AddressListState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AddressListState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  Address? get defaultAddress {
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }
}

class AddressListNotifier extends Notifier<AddressListState> {
  @override
  AddressListState build() {
    Future.microtask(() => loadAddresses());
    return AddressListState.initial();
  }

  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(addressRepositoryProvider);
      final addresses = await repository.getAddresses();
      state = state.copyWith(addresses: addresses, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Failure: ', ''),
      );
    }
  }

  Future<bool> createAddress({
    required String label,
    required String line1,
    String? line2,
    required String city,
    required String pincode,
    required double lat,
    required double lng,
    bool isDefault = false,
  }) async {
    try {
      final repository = ref.read(addressRepositoryProvider);
      await repository.createAddress(
        label: label,
        line1: line1,
        line2: line2,
        city: city,
        pincode: pincode,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
      );
      await loadAddresses();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceFirst('Failure: ', ''));
      return false;
    }
  }

  Future<bool> updateAddress({
    required String id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? pincode,
    double? lat,
    double? lng,
    bool? isDefault,
  }) async {
    try {
      final repository = ref.read(addressRepositoryProvider);
      await repository.updateAddress(
        id: id,
        label: label,
        line1: line1,
        line2: line2,
        city: city,
        pincode: pincode,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
      );
      await loadAddresses();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceFirst('Failure: ', ''));
      return false;
    }
  }

  Future<void> setDefaultAddress(String id) async {
    await updateAddress(id: id, isDefault: true);
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final repository = ref.read(addressRepositoryProvider);
      await repository.deleteAddress(id);
      await loadAddresses();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceFirst('Failure: ', ''));
      return false;
    }
  }
}

final addressListNotifierProvider =
    NotifierProvider<AddressListNotifier, AddressListState>(() {
  return AddressListNotifier();
});
