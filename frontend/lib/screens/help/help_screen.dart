import 'package:flutter/material.dart';
import 'help_videos_screen.dart'; // Import the second screen

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF206C5E);
    const Color bgColor = Color(0xFFF4F6FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpOption(
            context,
            icon: Icons.play_circle_outline_rounded,
            title: 'Help Videos',
            subtitle: 'Watch tutorials on how to use the app',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HelpVideosScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildHelpOption(
            context,
            icon: Icons.headset_mic_outlined,
            title: 'Contact Support',
            subtitle: 'Get in touch with our team for assistance',
            onTap: () {
              // Future implementation for Call/Chat
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF206C5E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Color(0xFF206C5E), size: 28),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
