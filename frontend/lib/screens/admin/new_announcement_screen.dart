import 'package:flutter/material.dart';
import '../../api/company_api_service.dart';
import '../../utils/announcement_titles.dart';
import '../../api/announcement_api_service.dart';
import '../../api/branch_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewAnnouncementScreen extends StatefulWidget {
  const NewAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<NewAnnouncementScreen> createState() => _NewAnnouncementScreenState();
}

class _NewAnnouncementScreenState extends State<NewAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _customTitleController = TextEditingController();
  String _selectedBranch = 'Loading branches...';
  String _selectedTitle = 'Select Title *';

  List<String> _branches = [];
  List<String> _titles = AnnouncementTitles.titles;
  late List<bool> _selectedBranches;
  late List<bool> _selectedTitles;
  bool _isLoading = true;
  bool _showCustomTitle = false;
  List<String> _branchIds = []; // Store actual company IDs
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _selectedBranches = [];
    _selectedTitles = List<bool>.filled(_titles.length, false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _customTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCompanyId = prefs.getString(
          'companyId'); // The company the admin is currently managing

      if (currentCompanyId == null) throw Exception('No Company selected');

      // Use your existing BranchApiService to get branches of THIS company
      final branchService = BranchApiService();
      final branchesData =
          await branchService.getCompanyBranches(currentCompanyId);

      setState(() {
        // Add "All Branches" as the first option manually
        _branches = ['All Branches'] + branchesData.map((b) => b.name).toList();

        // Store IDs. Index 0 is empty for "All Branches", then match others
        _branchIds = [''] + branchesData.map((b) => b.id).toList();

        _selectedBranches = List<bool>.filled(_branches.length, false);
        _selectedBranches[0] = true; // Default to All Branches
        _selectedBranch = 'All Branches';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading branches: $e');
      setState(() {
        _selectedBranch = 'Error loading branches';
        _isLoading = false;
      });
    }
  }

  void _openTitleSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _TitleSelectorSheet(
          titles: _titles,
          selected: List<bool>.from(_selectedTitles),
          onApply: (newSelected) {
            setState(() {
              _selectedTitles = newSelected;
              final selectedNames = <String>[];
              for (int i = 0; i < _titles.length; i++) {
                if (_selectedTitles[i]) selectedNames.add(_titles[i]);
              }
              if (selectedNames.contains('Others')) {
                _showCustomTitle = true;
                _selectedTitle = 'Others';
              } else {
                _showCustomTitle = false;
                _selectedTitle = selectedNames.isEmpty
                    ? 'Select Title *'
                    : selectedNames.first;
              }
            });
          },
        );
      },
    );
  }

  void _openBranchSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _BranchSelectorSheet(
          branches: _branches,
          selected: List<bool>.from(_selectedBranches),
          onApply: (newSelected) {
            setState(() {
              _selectedBranches = newSelected;
              // compute label
              final selectedNames = <String>[];
              for (int i = 0; i < _branches.length; i++) {
                if (_selectedBranches[i]) selectedNames.add(_branches[i]);
              }
              _selectedBranch = selectedNames.isEmpty
                  ? 'All Branches'
                  : selectedNames.join(', ');
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color topBarColor = Color(0xFF232B2F);
    const Color primaryGreen = Colors.blue;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Announcement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a new announcement for all your\nemployees to engage with them.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    _fieldLabel('Title *'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _openTitleSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 1),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTitle,
                              style: const TextStyle(
                                  fontSize: 15, color: Color(0xFF111827)),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFF9CA3AF)),
                          ],
                        ),
                      ),
                    ),

                    // Custom Title Field (shows when "Others" selected)
                    if (_showCustomTitle) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customTitleController,
                        decoration: InputDecoration(
                          hintText: 'Enter custom title',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 1),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Custom title is required'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Description
                    _fieldLabel('Description *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Eg. We have achieved our Sales Target.',
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.4,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Branch selector
                    _fieldLabel('Select Branch'),
                    const SizedBox(height: 6),
                    _isLoading
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB), width: 1),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: primaryGreen),
                                ),
                                const SizedBox(width: 8),
                                const Text('Loading branches...',
                                    style: TextStyle(color: Color(0xFF6B7280))),
                              ],
                            ),
                          )
                        : _selectedBranch.startsWith('Error')
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.red, width: 1),
                                  color: Colors.red.withOpacity(0.1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error,
                                        color: Colors.red[600], size: 20),
                                    const SizedBox(width: 8),
                                    Text(_selectedBranch,
                                        style:
                                            TextStyle(color: Colors.red[600])),
                                  ],
                                ),
                              )
                            : InkWell(
                                onTap: _branches.isEmpty
                                    ? null
                                    : _openBranchSelector,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedBranch,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF111827)),
                                      ),
                                      _branches.isNotEmpty
                                          ? const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Color(0xFF9CA3AF))
                                          : Icon(Icons.keyboard_arrow_down,
                                              color: Color(0xFFE5E7EB)),
                                    ],
                                  ),
                                ),
                              ),
                  ],
                ),
              ),
            ),
          ),

          // Send button bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    12), // Matching your app's rounded style
                gradient: const LinearGradient(
                  colors: [Color(0xFF206C5E), Color(0xFF2BA98A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF206C5E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: _isSending
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() != true) return;

                        final title = _selectedTitle == 'Others'
                            ? _customTitleController.text.trim()
                            : _selectedTitle;
                        if (title == 'Select Title *' || title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a title')),
                          );
                          return;
                        }

                        if (_selectedBranches.every((selected) => !selected)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please select at least one branch')),
                          );
                          return;
                        }

                        setState(() => _isSending = true);

                        try {
                          // Extract selected company IDs
                          final isAllBranches = _selectedBranches[0];
                          final selectedBranchIds = <String>[];

                          if (!isAllBranches) {
                            for (int i = 1; i < _selectedBranches.length; i++) {
                              if (_selectedBranches[i]) {
                                selectedBranchIds.add(_branchIds[i]);
                              }
                            }
                          }

                          await AnnouncementApiService.createAnnouncement(
                            title: title,
                            description: _descController.text.trim(),
                            targetBranchIds: selectedBranchIds, // Correct key
                            isAllBranches: isAllBranches, // Correct key
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Announcement sent successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.of(context)
                                .pop(true); // Return true to refresh list
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSending = false);
                        }
                      },
                child: _isSending
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text('Sending...',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Text('Send',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF4B5563),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TitleSelectorSheet extends StatefulWidget {
  final List<String> titles;
  final List<bool> selected;
  final ValueChanged<List<bool>> onApply;

  const _TitleSelectorSheet({
    Key? key,
    required this.titles,
    required this.selected,
    required this.onApply,
  }) : super(key: key);

  @override
  State<_TitleSelectorSheet> createState() => _TitleSelectorSheetState();
}

class _TitleSelectorSheetState extends State<_TitleSelectorSheet> {
  late List<bool> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List<bool>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    const blue = Colors.blue;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Select Title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // list
            Expanded(
              child: ListView.separated(
                itemCount: widget.titles.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final title = widget.titles[index];
                  final checked = _localSelected[index];

                  return ListTile(
                    onTap: () {
                      setState(() {
                        // Single selection for titles (unlike branches)
                        for (int i = 0; i < _localSelected.length; i++) {
                          _localSelected[i] = false;
                        }
                        _localSelected[index] = true;
                      });
                    },
                    title: Text(
                      title,
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    trailing: Checkbox(
                      value: checked,
                      onChanged: (val) {
                        setState(() {
                          for (int i = 0; i < _localSelected.length; i++) {
                            _localSelected[i] = false;
                          }
                          _localSelected[index] = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFF206C5E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  );
                },
              ),
            ),

            // apply button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
              ),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF206C5E), Color(0xFF2BA98A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    widget.onApply(_localSelected);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchSelectorSheet extends StatefulWidget {
  final List<String> branches;
  final List<bool> selected;
  final ValueChanged<List<bool>> onApply;

  const _BranchSelectorSheet({
    Key? key,
    required this.branches,
    required this.selected,
    required this.onApply,
  }) : super(key: key);

  @override
  State<_BranchSelectorSheet> createState() => _BranchSelectorSheetState();
}

class _BranchSelectorSheetState extends State<_BranchSelectorSheet> {
  late List<bool> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List<bool>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    const blue = Colors.blue;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 360, // bottom sheet height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Select Branches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // list
            Expanded(
              child: ListView.separated(
                itemCount: widget.branches.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final title = widget.branches[index];
                  final checked = _localSelected[index];

                  return ListTile(
                    onTap: () {
                      setState(() {
                        if (index == 0) {
                          final newVal = !_localSelected[0];
                          for (int i = 0; i < _localSelected.length; i++) {
                            _localSelected[i] = false;
                          }
                          _localSelected[0] = newVal;
                        } else {
                          _localSelected[index] = !_localSelected[index];
                          if (_localSelected[index]) {
                            _localSelected[0] = false;
                          }
                        }
                      });
                    },
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: Checkbox(
                      value: checked,
                      onChanged: (val) {
                        setState(() {
                          if (index == 0) {
                            final newVal = val ?? false;
                            for (int i = 0; i < _localSelected.length; i++) {
                              _localSelected[i] = false;
                            }
                            _localSelected[0] = newVal;
                          } else {
                            _localSelected[index] = val ?? false;
                            if (val == true) _localSelected[0] = false;
                          }
                        });
                      },
                      activeColor: const Color(0xFF206C5E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),

            // apply button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF206C5E), Color(0xFF2BA98A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    widget.onApply(_localSelected);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
