// lib/widgets/network_banner.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        // 1. Nếu chưa có dữ liệu → tạm coi là offline
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return _buildBanner(context, true);
        }

        // 2. Kiểm tra xem có kết nối thực sự không
        final results = snapshot.data!;
        final hasInternet = results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.vpn) ||
            results.contains(ConnectivityResult.ethernet) ||
            results.contains(ConnectivityResult.other);

        // Nếu KHÔNG có bất kỳ kết nối nào → offline
        final isOffline = !hasInternet;

        if (isOffline) {
          return _buildBanner(context, true);
        }

        // Online → ẩn banner
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBanner(BuildContext context, bool isOffline) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: isOffline ? Colors.red.shade600 : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Text(
          isOffline
              ? "Mất kết nối mạng • Một số chức năng tạm dừng"
              : "",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}