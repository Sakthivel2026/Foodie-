import '../entities/address.dart';

abstract class AddressRepository {
  Future<List<Address>> getAddresses();
  Future<Address> createAddress({
    required String label,
    required String line1,
    String? line2,
    required String city,
    required String pincode,
    required double lat,
    required double lng,
    bool isDefault = false,
  });
  Future<Address> updateAddress({
    required String id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? pincode,
    double? lat,
    double? lng,
    bool? isDefault,
  });
  Future<void> deleteAddress(String id);
}
