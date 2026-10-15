import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_data_source.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource _remoteDataSource;

  AddressRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Address>> getAddresses() => _remoteDataSource.getAddresses();

  @override
  Future<Address> createAddress({
    required String label,
    required String line1,
    String? line2,
    required String city,
    required String pincode,
    required double lat,
    required double lng,
    bool isDefault = false,
  }) =>
      _remoteDataSource.createAddress(
        label: label,
        line1: line1,
        line2: line2,
        city: city,
        pincode: pincode,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
      );

  @override
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
  }) =>
      _remoteDataSource.updateAddress(
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

  @override
  Future<void> deleteAddress(String id) => _remoteDataSource.deleteAddress(id);
}
