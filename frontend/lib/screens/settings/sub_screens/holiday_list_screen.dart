import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Add intl: ^0.18.0 to pubspec.yaml if needed, or use basic formatting
import '../../../../api/holiday_api_service.dart';
import '../../../../models/holiday_model.dart';

class HolidayListScreen extends StatefulWidget {
  const HolidayListScreen({Key? key}) : super(key: key);

  @override
  State<HolidayListScreen> createState() => _HolidayListScreenState();
}

class _HolidayListScreenState extends State<HolidayListScreen> {
  final HolidayApiService _api = HolidayApiService();

  // Data
  int _selectedYear = DateTime.now().year;
  List<Holiday> _allHolidays = []; // Combined List
  final Set<String> _addedIds = {}; // IDs that are "saved/active"

  bool _isLoading = true;
  bool _isFetchingGovt = false;
  bool _isSaving = false;
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyId');
    if (_companyId != null) {
      _fetchCompanyHolidays();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 1. Load Saved Data
  Future<void> _fetchCompanyHolidays() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getCompanyHolidays(_companyId!, _selectedYear);
      if (mounted) {
        setState(() {
          _allHolidays = list;
          _addedIds.clear();
          // Mark all loaded items as "added"
          for (var h in list) {
            _addedIds.add(h.id);
          }
          _sortHolidays();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load holidays', isError: true);
      }
    }
  }

  // 2. Fetch Govt Data and Merge
  Future<void> _fetchGovtHolidays() async {
    setState(() => _isFetchingGovt = true);
    try {
      final list = await _api.getPublicHolidays(_selectedYear);

      if (mounted) {
        setState(() {
          // Add only if not already present (based on ID)
          final existingIds = _allHolidays.map((h) => h.id).toSet();
          final newItems = list.where((h) => !existingIds.contains(h.id));

          _allHolidays.addAll(newItems);
          _sortHolidays();
          _isFetchingGovt = false;
        });
        _showSnack('Loaded government holidays for $_selectedYear');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingGovt = false);
        _showSnack('Failed to fetch government holidays', isError: true);
      }
    }
  }

  void _sortHolidays() {
    _allHolidays.sort((a, b) => a.date.compareTo(b.date));
  }

  // --- ACTIONS ---

  void _addToList(String id) {
    setState(() {
      _addedIds.add(id);
    });
  }

  void _removeFromList(String id) {
    setState(() {
      _addedIds.remove(id);
      // Also remove from view immediately, like React
      _allHolidays.removeWhere((h) => h.id == id);
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    // Filter only "added" holidays
    final toSave = _allHolidays.where((h) => _addedIds.contains(h.id)).toList();

    try {
      await _api.saveHolidays(_companyId!, _selectedYear, toSave);
      _showSnack('Company holidays updated successfully');
      // Reload clean state
      _fetchCompanyHolidays();
    } catch (e) {
      _showSnack('Failed to save', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddHolidayDialog(
        onAdd: (name, date) {
          final newH = Holiday(
              name: name, date: date, type: 'Company', source: 'manual');
          if (_allHolidays.any((h) => h.id == newH.id)) {
            _showSnack('This holiday already exists', isError: true);
          } else {
            setState(() {
              _allHolidays.add(newH);
              _addedIds.add(newH.id);
              _sortHolidays();
            });
            _showSnack('Custom holiday added');
          }
        },
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF206C5E),
      ),
    );
  }

  // Helper for Date Display (Manual formatting to avoid intl dependency if preferred)
  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      // Simple format: "Fri, January 26, 2024"
      const months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ];
      const weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      return "${weekDays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}";
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFF14B8A6); // Teal

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Holidays - $_selectedYear',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          // Year Selector
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600),
                items: [_selectedYear - 1, _selectedYear, _selectedYear + 1]
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedYear = val);
                    _fetchCompanyHolidays();
                  }
                },
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Header Actions Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isFetchingGovt ? null : _fetchGovtHolidays,
                        icon: _isFetchingGovt
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cloud_download_outlined,
                                size: 18),
                        label: const Text('Get Govt Holidays',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Custom',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 18, color: Colors.white),
                    label: const Text('Save Changes',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allHolidays.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.calendar_month,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No holidays found',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _allHolidays.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final holiday = _allHolidays[index];
                          final isAdded = _addedIds.contains(holiday.id);

                          return Container(
                            decoration: BoxDecoration(
                              color:
                                  isAdded ? Colors.white : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAdded
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      holiday.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: holiday.type == 'National'
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      holiday.type,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: holiday.type == 'National'
                                            ? const Color(0xFF1D4ED8)
                                            : const Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  _formatDate(holiday.date),
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              trailing: isAdded
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removeFromList(holiday.id),
                                    )
                                  : OutlinedButton(
                                      onPressed: () => _addToList(holiday.id),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        side: BorderSide(color: primary),
                                      ),
                                      child: Text('Add',
                                          style: TextStyle(color: primary)),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Add Custom Dialog ---

class _AddHolidayDialog extends StatefulWidget {
  final Function(String name, String date) onAdd;

  const _AddHolidayDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<_AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<_AddHolidayDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  String? _date; // YYYY-MM-DD

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Custom Holiday',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Holiday Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(_date ?? 'Select Date',
                    style: TextStyle(
                        color: _date == null ? Colors.grey : Colors.black)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_nameCtrl.text.isNotEmpty && _date != null) {
                      widget.onAdd(_nameCtrl.text.trim(), _date!);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6), // Teal
                  ),
                  child: const Text('Add Holiday',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
