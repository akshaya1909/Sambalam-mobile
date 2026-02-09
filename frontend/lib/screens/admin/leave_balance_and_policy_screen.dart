import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/leave_api_service.dart';
import '../../api/leave_type_api_service.dart';
import '../../models/leave_type_model.dart';

class LeaveBalancesAndPolicyScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const LeaveBalancesAndPolicyScreen({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<LeaveBalancesAndPolicyScreen> createState() =>
      _LeaveBalancesAndPolicyScreenState();
}

class _LeaveBalancesAndPolicyScreenState
    extends State<LeaveBalancesAndPolicyScreen> {
  final _leaveApi = LeaveApiService();
  final _typeApi = LeaveTypeApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String _activeTab = "balance";
  String _leaveCycle = "Monthly";

  List<LeaveType> _allTypes = [];
  Map<String, TextEditingController> _allowedControllers = {};
  Map<String, TextEditingController> _carryControllers = {};
  Map<String, TextEditingController> _balanceControllers = {};

  String _newLeaveStatus = "Paid"; // Default for the popup
  final TextEditingController _typeNameController = TextEditingController();

  final Color primaryDeepTeal = const Color(0xFF064E3B);
  final Color primaryTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);

  @override
  void dispose() {
    _allowedControllers.values.forEach((c) => c.dispose());
    _carryControllers.values.forEach((c) => c.dispose());
    _balanceControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";

      final results = await Future.wait([
        _typeApi.getLeaveTypes(companyId),
        _leaveApi.getLeaveBalance(
            employeeId: widget.employeeId, companyId: companyId),
      ]);

      _allTypes = results[0] as List<LeaveType>;
      final policyData = results[1] as Map<String, dynamic>;

      // IMPORTANT: Initialize controllers for ALL types immediately
      // to prevent null errors in the build method.
      for (var type in _allTypes) {
        _allowedControllers[type.id] = TextEditingController(text: "0");
        _carryControllers[type.id] = TextEditingController(text: "0");
        _balanceControllers[type.id] = TextEditingController(text: "0");
      }

      if (policyData['data'] != null) {
        _leaveCycle = policyData['data']['policyType'] ?? "Monthly";
        final List policies = policyData['data']['policies'] ?? [];
        final List balances = policyData['data']['balances'] ?? [];

        for (var type in _allTypes) {
          final p = policies.firstWhere(
            (item) =>
                (item['leaveTypeId']['_id'] ?? item['leaveTypeId']) == type.id,
            orElse: () => null,
          );
          if (p != null) {
            _allowedControllers[type.id]!.text =
                p['allowedLeaves']?.toString() ?? "0";
            _carryControllers[type.id]!.text =
                p['carryForwardLeaves']?.toString() ?? "0";
          }

          final b = balances.firstWhere(
            (item) =>
                (item['leaveTypeId']['_id'] ?? item['leaveTypeId']) == type.id,
            orElse: () => null,
          );
          if (b != null) {
            _balanceControllers[type.id]!.text =
                b['current']?.toString() ?? "0";
          }
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAddLeaveType() async {
    if (_typeNameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";

      // 1. Call API with Name and Type (Paid/Unpaid)
      await _typeApi.createLeaveType(
          companyId, _typeNameController.text.trim());

      // 2. Clear inputs and close modal
      _typeNameController.clear();
      if (mounted) Navigator.pop(context);

      // 3. Refresh Data to reflect new type in list
      await _fetchInitialData();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Custom leave type added successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildTabsSelector()),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _activeTab == "balance"
                        ? _buildBalanceTab()
                        : _buildPolicyTab(),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160.0, // Matches Penalty screen height
      pinned: true,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDeepTeal, primaryTeal, secondaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employeeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Matches high-end typography
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Leave Policy Management", // Specific to this screen
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        // Using arrow_back_ios_new for the premium professional look
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Color.fromARGB(255, 218, 196, 196), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTabsSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          _tabButton("balance", "Leave Balance"),
          _tabButton("policy", "Leave Policy"),
        ],
      ),
    );
  }

  Widget _tabButton(String id, String label) {
    bool isSelected = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? secondaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceTab() {
    return Column(
      children: [
        _buildSectionCard(
          title: "Adjust Balances",
          child: Column(
            children: _allTypes
                .map((t) => _buildInputField(
                    t.name, _balanceControllers[t.id]!, "leaves"))
                .toList(),
          ),
        ),
        const Spacer(),
        _buildGradientButton("Update Balances", _saveBalances),
      ],
    );
  }

  Widget _buildPolicyTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildCycleSwitch(),
          const SizedBox(height: 24),

          // --- ADDED THIS ROW HERE ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Leave Type",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B))),
                TextButton.icon(
                  onPressed: () => _showAddCustomLeaveDialog(),
                  icon:
                      const Icon(Icons.add, size: 18, color: Color(0xFF2BA98A)),
                  label: const Text("Add Custom type",
                      style: TextStyle(
                          color: Color(0xFF2BA98A),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ---------------------------

          ..._allTypes.map((type) => _buildPolicyItem(type)).toList(),
          const SizedBox(height: 24),
          _buildGradientButton("Update Leave Policy", _savePolicy),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCycleSwitch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Leave Cycle",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ToggleButtons(
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: secondaryTeal,
            constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
            isSelected: [_leaveCycle == "Monthly", _leaveCycle == "Yearly"],
            onPressed: (index) =>
                _handleCycleChange(index == 0 ? "Monthly" : "Yearly"),
            children: const [Text("Monthly"), Text("Yearly")],
          )
        ],
      ),
    );
  }

  Widget _buildPolicyItem(LeaveType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF206C5E))),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildInputField("Allowed",
                      _allowedControllers[type.id]!, "per $_leaveCycle")),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildInputField(
                      "Carry Forward", _carryControllers[type.id]!, "max")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController ctrl, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        child
      ]),
    );
  }

  Widget _buildGradientButton(String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryTeal, secondaryTeal]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: primaryTeal.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: _isSaving ? null : onTap,
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
        ),
      ),
    );
  }

  // --- ACTIONS ---

  void _handleCycleChange(String cycle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Policy?"),
        content: Text(
            "Switching to $cycle will delete the current configuration for this employee. Continue?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _leaveApi.resetPolicy(widget.employeeId);
              setState(() => _leaveCycle = cycle);
              _fetchInitialData();
            },
            child: const Text("Reset & Switch",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _savePolicy() async {
    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> policies = _allTypes
          .map((t) => {
                "leaveTypeId": t.id,
                "allowedLeaves": int.parse(_allowedControllers[t.id]!.text),
                "carryForwardLeaves": int.parse(_carryControllers[t.id]!.text),
              })
          .toList();

      await _leaveApi.upsertLeavePolicy(
        employeeId: widget.employeeId,
        policyType: _leaveCycle,
        policies: policies,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Policy Updated Successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveBalances() async {
    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> balances = _allTypes
          .map((t) => {
                "leaveTypeId": t.id,
                "current": int.parse(_balanceControllers[t.id]!.text),
              })
          .toList();

      await _leaveApi.updateBalances(
          employeeId: widget.employeeId, balances: balances);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Balances Adjusted Successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showAddCustomLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(// Important to handle internal radio button state
              builder: (context, setModalState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Custom Leave Type",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Leave Name",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _typeNameController,
                decoration: InputDecoration(
                  hintText: "e.g. Paternity Leave",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Leave Status",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Paid", style: TextStyle(fontSize: 14)),
                      value: "Paid",
                      groupValue: _newLeaveStatus,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) =>
                          setModalState(() => _newLeaveStatus = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title:
                          const Text("Unpaid", style: TextStyle(fontSize: 14)),
                      value: "Unpaid",
                      groupValue: _newLeaveStatus,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) =>
                          setModalState(() => _newLeaveStatus = val!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleAddLeaveType,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryTeal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text("Add Type",
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }
}
