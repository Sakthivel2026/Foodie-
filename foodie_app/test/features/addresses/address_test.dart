import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/addresses/domain/entities/address.dart';
import 'package:foodie_app/features/addresses/presentation/providers/address_provider.dart';

void main() {
  group('Address Unit & Logic Tests', () {
    final addr1 = Address(
      id: 'addr-1',
      userId: 'user-1',
      label: 'Home',
      line1: '123 Main St',
      line2: 'Apt 4B',
      city: 'Bengaluru',
      pincode: '560001',
      lat: 12.9716,
      lng: 77.5946,
      isDefault: false,
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    final addr2 = Address(
      id: 'addr-2',
      userId: 'user-1',
      label: 'Work',
      line1: '456 Tech Park',
      line2: null,
      city: 'Bengaluru',
      pincode: '560037',
      lat: 12.9345,
      lng: 77.6242,
      isDefault: true,
      createdAt: DateTime.parse('2026-10-04T01:00:00.000Z'),
    );

    test('Address.fromJson parses API response with numeric values correctly', () {
      final json = {
        'id': 'addr-1',
        'user_id': 'user-1',
        'label': 'Home',
        'line1': '123 Main St',
        'line2': 'Apt 4B',
        'city': 'Bengaluru',
        'pincode': '560001',
        'lat': 12.9716,
        'lng': 77.5946,
        'is_default': false,
        'created_at': '2026-10-04T00:00:00.000Z',
      };

      final parsed = Address.fromJson(json);

      expect(parsed.id, 'addr-1');
      expect(parsed.label, 'Home');
      expect(parsed.isDefault, isFalse);
      expect(parsed.lat, 12.9716);
      expect(parsed.lng, 77.5946);
    });

    test('Address.fromJson parses PostgreSQL string numeric lat and lng without error', () {
      final json = {
        'id': 'addr-pg-1',
        'user_id': 'user-1',
        'label': 'Work',
        'line1': '456 Tech Park',
        'line2': null,
        'city': 'Bengaluru',
        'pincode': '560037',
        'lat': '12.9345000',
        'lng': '77.6242000',
        'is_default': true,
        'created_at': '2026-10-04T01:00:00.000Z',
      };

      final parsed = Address.fromJson(json);

      expect(parsed.id, 'addr-pg-1');
      expect(parsed.label, 'Work');
      expect(parsed.isDefault, isTrue);
      expect(parsed.lat, 12.9345);
      expect(parsed.lng, 77.6242);
      expect(parsed.line2, isNull);
    });


    test('AddressListState returns default address correctly', () {
      final stateWithDefault = AddressListState(
        addresses: [addr1, addr2],
        isLoading: false,
      );

      expect(stateWithDefault.defaultAddress?.id, 'addr-2');

      final stateWithoutDefaultFlag = AddressListState(
        addresses: [addr1],
        isLoading: false,
      );

      // Falls back to first address if none marked default
      expect(stateWithoutDefaultFlag.defaultAddress?.id, 'addr-1');
    });
  });
}
