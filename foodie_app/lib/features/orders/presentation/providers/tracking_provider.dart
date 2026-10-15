import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import 'order_provider.dart';

class TrackingState {
  final OrderEntity? order;
  final String status;
  final LatLng? driverLocation;
  final bool isConnected;
  final bool isLoading;
  final String? errorMessage;

  const TrackingState({
    this.order,
    this.status = 'PLACED',
    this.driverLocation,
    this.isConnected = false,
    this.isLoading = true,
    this.errorMessage,
  });

  TrackingState copyWith({
    OrderEntity? order,
    String? status,
    LatLng? driverLocation,
    bool? isConnected,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TrackingState(
      order: order ?? this.order,
      status: status ?? this.status,
      driverLocation: driverLocation ?? this.driverLocation,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TrackingNotifier extends Notifier<TrackingState> {
  final String orderId;

  TrackingNotifier(this.orderId);

  io.Socket? _socket;
  Timer? _pollingTimer;

  @override
  TrackingState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
      _socket?.disconnect();
      _socket?.dispose();
    });

    Future.microtask(() => _init());
    return const TrackingState();
  }

  OrderRepository get _orderRepo => ref.read(orderRepositoryProvider);
  StorageService get _storage => ref.read(storageServiceProvider);

  Future<void> _init() async {
    await fetchInitialOrder();
    await connectSocket();
    _startFallbackPolling();
  }

  Future<void> fetchInitialOrder() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final order = await _orderRepo.getOrderById(orderId);
      state = state.copyWith(
        order: order,
        status: order.status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> connectSocket() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;

      final baseUrl = Env.apiBaseUrl;

      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      _socket?.onConnect((_) {
        state = state.copyWith(isConnected: true);
        _socket?.emit('join_order', {'orderId': orderId});
      });

      _socket?.onDisconnect((_) {
        state = state.copyWith(isConnected: false);
      });

      _socket?.onConnectError((_) {
        state = state.copyWith(isConnected: false);
      });

      _socket?.on('status_updated', (data) {
        if (data is Map && data['orderId'] == orderId) {
          final newStatus = data['status'] as String?;
          if (newStatus != null) {
            state = state.copyWith(status: newStatus);
          }
        }
      });

      _socket?.on('location_updated', (data) {
        if (data is Map && data['orderId'] == orderId) {
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            state = state.copyWith(driverLocation: LatLng(lat, lng));
          }
        }
      });

      _socket?.connect();
    } catch (_) {
      state = state.copyWith(isConnected: false);
    }
  }

  void _startFallbackPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!state.isConnected) {
        try {
          final order = await _orderRepo.getOrderById(orderId);
          state = state.copyWith(
            order: order,
            status: order.status,
          );
        } catch (_) {}
      }
    });
  }
}

final trackingNotifierProvider =
    NotifierProvider.family<TrackingNotifier, TrackingState, String>(TrackingNotifier.new);
