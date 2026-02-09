import 'package:flutter/material.dart';
import '../../api/penalty_and_overtime_api_service.dart';

class PenaltyAndOvertimeScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const PenaltyAndOvertimeScreen({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<PenaltyAndOvertimeScreen> createState() =>
      _PenaltyAndOvertimeScreenState();
}

class _PenaltyAndOvertimeScreenState extends State<PenaltyAndOvertimeScreen> {
  final _api = PenaltyAndOvertimeApiService();
  bool _isLoading = true;

  // Form Controllers
  final TextEditingController _lateDays = TextEditingController();
  final TextEditingController _lateGrace = TextEditingController();
  final TextEditingController _lateRate = TextEditingController();
  final TextEditingController _earlyDays = TextEditingController();
  final TextEditingController _earlyGrace = TextEditingController();
  final TextEditingController _earlyRate = TextEditingController();
  final TextEditingController _otAfter = TextEditingController();
  final TextEditingController _otHourlyRate = TextEditingController();
  final TextEditingController _otHolidayRate = TextEditingController();

  // Premium Theme Colors
  final Color primaryDeepTeal = const Color(0xFF064E3B); // Deep Emerald
  final Color primaryTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color accentGold = const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadAllPolicies();
  }

  Future<void> _loadAllPolicies() async {
    try {
      final results = await Future.wait([
        _api.getLateComingPolicy(widget.employeeId),
        _api.getEarlyLeavingPolicy(widget.employeeId),
        _api.getOvertimePolicy(widget.employeeId),
      ]);

      final late = results[0]['lateComingPolicy'];
      final early = results[1]['earlyLeavingPolicy'];
      final ot = results[2]['overtimePolicy'];

      setState(() {
        _lateDays.text = late['allowedLateDays']?.toString() ?? "0";
        _lateGrace.text = late['onlyDeductIfLateByMoreThan']?.toString() ?? "0";
        _lateRate.text = late['amount']?.toString() ?? "0";
        _earlyDays.text = early['allowedEarlyLeavingDays']?.toString() ?? "0";
        _earlyGrace.text = early['onlyDeductIfEarlierThan']?.toString() ?? "0";
        _earlyRate.text = early['amount']?.toString() ?? "0";
        _otAfter.text =
            ot['workingDays']['overtimeConsideredAfter']?.toString() ?? "0";
        _otHourlyRate.text = ot['workingDays']['amount']?.toString() ?? "0";
        _otHolidayRate.text =
            ot['weekoffsAndHolidays']['amountPublicHolidayPay']?.toString() ??
                "0";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Sleek Header
          SliverAppBar(
            expandedHeight: 160.0,
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Policy Management",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Policy Sections
          SliverToBoxAdapter(
            child: _isLoading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: CircularProgressIndicator()))
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSectionHeader("Fines & Deductions"),
                        _buildProfessionalCard(
                          title: "Late Arrival",
                          subtitle: "Deduct salary for coming late",
                          icon: Icons.history_toggle_off_rounded,
                          accentColor: Colors.orange.shade700,
                          form: _buildLateComingForm(),
                          onSave: _saveLateFine,
                        ),
                        const SizedBox(height: 20),
                        _buildProfessionalCard(
                          title: "Early Leaving",
                          subtitle: "Fines for leaving before shift end",
                          icon: Icons.directions_run_rounded,
                          accentColor: Colors.red.shade700,
                          form: _buildEarlyLeavingForm(),
                          onSave: _saveEarlyFine,
                        ),
                        const SizedBox(height: 30),
                        _buildSectionHeader("Earnings & Overtime"),
                        _buildProfessionalCard(
                          title: "Overtime (OT)",
                          subtitle: "Extra pay for additional hours",
                          icon: Icons.add_business_rounded,
                          accentColor: Colors.blue.shade700,
                          form: _buildOvertimeForm(),
                          onSave: _saveOvertime,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: primaryTeal,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey.shade800,
                letterSpacing: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget form,
    required VoidCallback onSave,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: Colors.grey.shade400,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF1E293B)),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  const Divider(height: 30),
                  form,
                  const SizedBox(height: 25),
                  _buildSmartButton(onSave, "Apply Policy"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      IconData icon, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: primaryTeal),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(top: 14, right: 12),
                child: Text(unit,
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              filled: true,
              fillColor: bgLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: secondaryTeal, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLateComingForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildInputField(
                    "Limit", _lateDays, Icons.calendar_month, "Days")),
            const SizedBox(width: 12),
            Expanded(
                child: _buildInputField(
                    "Grace", _lateGrace, Icons.av_timer, "Mins")),
          ],
        ),
        _buildInputField(
            "Penalty Rate", _lateRate, Icons.money_off_rounded, "₹ / Day"),
      ],
    );
  }

  Widget _buildEarlyLeavingForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildInputField(
                    "Limit", _earlyDays, Icons.calendar_month, "Days")),
            const SizedBox(width: 12),
            Expanded(
                child: _buildInputField(
                    "Buffer", _earlyGrace, Icons.lock_clock, "Mins")),
          ],
        ),
        _buildInputField(
            "Penalty Rate", _earlyRate, Icons.money_off_rounded, "₹ / Day"),
      ],
    );
  }

  Widget _buildOvertimeForm() {
    return Column(
      children: [
        _buildInputField("Shift Limit (Buffer)", _otAfter, Icons.timer, "Mins"),
        _buildInputField("Standard OT Pay", _otHourlyRate,
            Icons.payments_rounded, "₹ / Hour"),
        _buildInputField("Holiday OT Pay", _otHolidayRate,
            Icons.celebration_rounded, "₹ / Day"),
      ],
    );
  }

  Widget _buildSmartButton(VoidCallback onTap, String label) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryTeal, secondaryTeal]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  // --- API Handlers ---
  void _saveLateFine() async {
    bool ok = await _api.updateLateComing(widget.employeeId, {
      "allowedLateDays": int.tryParse(_lateDays.text) ?? 0,
      "onlyDeductIfLateByMoreThan": int.tryParse(_lateGrace.text) ?? 0,
      "amount": int.tryParse(_lateRate.text) ?? 0,
      "deductionType": "Fixed Daily Rate",
      "deductionMode": "No, use a fixed deduction for late arrival"
    });
    _showSnackBar(ok, "Late Fine Policy");
  }

  void _saveEarlyFine() async {
    bool ok = await _api.updateEarlyLeaving(widget.employeeId, {
      "allowedEarlyLeavingDays": int.tryParse(_earlyDays.text) ?? 0,
      "onlyDeductIfEarlierThan": int.tryParse(_earlyGrace.text) ?? 0,
      "amount": int.tryParse(_earlyRate.text) ?? 0,
      "deductionType": "Fixed Daily Rate",
      "deductionMode": "No, use a fixed deduction for early leaving"
    });
    _showSnackBar(ok, "Early Leaving Policy");
  }

  void _saveOvertime() async {
    bool ok = await _api.updateOvertime(widget.employeeId, {
      "workingDays": {
        "overtimeConsideredAfter": int.tryParse(_otAfter.text) ?? 0,
        "amount": int.tryParse(_otHourlyRate.text) ?? 0,
        "extraHoursPay": "Fixed Hourly Rate"
      },
      "weekoffsAndHolidays": {
        "amountPublicHolidayPay": int.tryParse(_otHolidayRate.text) ?? 0,
        "publicHolidayPay": "Fixed Daily Rate",
        "weekOffPay": "Fixed Daily Rate",
        "amountWeekOffPay": int.tryParse(_otHolidayRate.text) ?? 0,
      }
    });
    _showSnackBar(ok, "Overtime Policy");
  }

  void _showSnackBar(bool success, String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: success ? secondaryTeal : Colors.redAccent,
      content: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
          const SizedBox(width: 12),
          Text("$title ${success ? 'Updated' : 'Failed'}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ));
  }
}
