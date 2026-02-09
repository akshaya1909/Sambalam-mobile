import 'package:flutter/material.dart';

class HelpVideosScreen extends StatefulWidget {
  const HelpVideosScreen({Key? key}) : super(key: key);

  @override
  State<HelpVideosScreen> createState() => _HelpVideosScreenState();
}

class _HelpVideosScreenState extends State<HelpVideosScreen> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Attendance', 'Payroll', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help Videos',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Horizontal Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedFilter == filters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filters[index]),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => selectedFilter = filters[index]),
                    selectedColor: const Color(0xFF206C5E),
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Video List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildVideoCard("How to Add Staff on Sambalam?", "02:39"),
                _buildVideoCard("How to Onboard Employees?", "02:37"),
                _buildVideoCard("How to Active/Inactive Staff?", "02:37"),
                _buildVideoCard("Background Verification Flow", "03:15"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(String title, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Placeholder
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                      colors: [Colors.teal[700]!, Colors.teal[400]!]),
                ),
                child: const Icon(Icons.play_circle_fill,
                    color: Colors.white, size: 50),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(duration,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
