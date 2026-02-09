import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class GlobalConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const GlobalConnectivityWrapper({Key? key, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      // 1. Provide initial connection state to avoid starting as 'null'
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        // 2. If the snapshot hasn't received data yet, don't assume offline.
        // Wait for the stream to provide the actual status.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return child;
        }

        final List<ConnectivityResult> results = snapshot.data ?? [];

        // 3. Only trigger offline if we explicitly have data and it says 'none'
        final bool isOffline = results.contains(ConnectivityResult.none);

        return Stack(
          children: [
            child,
            if (isOffline) _buildNoInternetScreen(context),
          ],
        );
      },
    );
  }

  Widget _buildNoInternetScreen(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 100, color: Color(0xFF206C5E)),
            const SizedBox(height: 32),
            const Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Please check your network settings to continue using Sambalam.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  // This manually triggers a check, which will fire the stream again
                  await Connectivity().checkConnectivity();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF206C5E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("TRY AGAIN",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
