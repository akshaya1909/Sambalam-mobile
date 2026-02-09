import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/holiday_api_service.dart';
import '../../../../models/holiday_model.dart';

class HolidayListScreen extends StatefulWidget {
  final String companyId;

  const HolidayListScreen({Key? key, required this.companyId})
      : super(key: key);

  @override
  State<HolidayListScreen> createState() => _HolidayListScreenState();
}

class _HolidayListScreenState extends State<HolidayListScreen> {
  final _api = HolidayApiService();
  int _selectedYear = DateTime.now().year;
  List<Holiday> _holidays = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    try {
      final list =
          await _api.getCompanyHolidays(widget.companyId, _selectedYear);
      if (mounted) {
        setState(() {
          _holidays = list;
          // Sort by date ascending
          _holidays.sort((a, b) => a.date.compareTo(b.date));
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFEC4899); // Pink to match icon
    const Color bg = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Holidays',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // Year Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: primary),
                style: GoogleFonts.inter(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                onChanged: (int? newValue) {
                  if (newValue != null && newValue != _selectedYear) {
                    setState(() => _selectedYear = newValue);
                    _loadHolidays();
                  }
                },
                items: [_selectedYear - 1, _selectedYear, _selectedYear + 1]
                    .map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _hasError
              ? _buildErrorState()
              : _holidays.isEmpty
                  ? _buildEmptyState()
                  : _buildList(primary),
    );
  }

  Widget _buildList(Color primary) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemCount: _holidays.length,
      itemBuilder: (context, index) {
        final holiday = _holidays[index];
        final date = DateTime.tryParse(holiday.date);

        // Formatting
        final day = date != null ? DateFormat('dd').format(date) : '--';
        final month = date != null ? DateFormat('MMM').format(date) : '---';
        final weekday = date != null ? DateFormat('EEEE').format(date) : '';

        // Check if holiday is in the past
        final isPast = date != null &&
            date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date Box
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade100
                        : primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey : primary,
                        ),
                      ),
                      Text(
                        month.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPast ? Colors.grey : primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holiday.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isPast
                              ? Colors.grey.shade600
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            weekday,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: holiday.type == 'National'
                                  ? Colors.blue.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              holiday.type,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: holiday.type == 'National'
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No holidays found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your work days!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Failed to load holidays',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
          TextButton(
            onPressed: _loadHolidays,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
