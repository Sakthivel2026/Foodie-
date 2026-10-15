import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/address.dart';

class AddressRemoteDataSource {
  final Dio _dio;

  AddressRemoteDataSource(this._dio);

  Future<List<Address>> getAddresses() async {
    try {
      final response = await _dio.get('/addresses');
      final list = response.data as List<dynamic>;
      return list.map((item) => Address.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<Address> createAddress({
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
      final data = <String, dynamic>{
        'label': label,
        'line1': line1,
        'city': city,
        'pincode': pincode,
        'lat': lat,
        'lng': lng,
        'is_default': isDefault,
      };
      if (line2 != null && line2.isNotEmpty) {
        data['line2'] = line2;
      }

      final response = await _dio.post('/addresses', data: data);
      return Address.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

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
  }) async {
    try {
      final data = <String, dynamic>{};
      if (label != null) data['label'] = label;
      if (line1 != null) data['line1'] = line1;
      if (line2 != null) data['line2'] = line2;
      if (city != null) data['city'] = city;
      if (pincode != null) data['pincode'] = pincode;
      if (lat != null) data['lat'] = lat;
      if (lng != null) data['lng'] = lng;
      if (isDefault != null) data['is_default'] = isDefault;

      final response = await _dio.put('/addresses/$id', data: data);
      return Address.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _dio.delete('/addresses/$id');
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}
