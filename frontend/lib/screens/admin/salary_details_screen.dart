import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/manage_salary_template_screen.dart';
import '../../api/salary_api_service.dart';
import '../../api/salary_template_api_service.dart';
import '../../../models/salary_template_model.dart';

class SalaryDetailsScreen extends StatefulWidget {
  final String employeeId; // Internal MongoDB ID
  final String staffName;

  const SalaryDetailsScreen(
      {Key? key, required this.employeeId, required this.staffName})
      : super(key: key);

  @override
  State<SalaryDetailsScreen> createState() => _SalaryDetailsScreenState();
}

class _SalaryDetailsScreenState extends State<SalaryDetailsScreen> {
  final SalaryApiService _salaryApi = SalaryApiService();
  final SalaryTemplateApiService _templateApi = SalaryTemplateApiService();

  final Color scaffoldBg = const Color(0xFFF4F6FB);
  bool _isLoading = true;
  bool _isSaving = false;

  // --- Form State ---
  String _effectiveDate = DateFormat('yyyy-MM').format(DateTime.now());
  String _salaryType = "Per Month";
  String _salaryStructure = "Custom";
  double _ctcAmount = 0.0;
  List<SalaryTemplate> _templates = [];

  // Earnings & Deductions
  List<Map<String, dynamic>> _earnings = [];
  List<Map<String, dynamic>> _deductions = [];
  final TextEditingController _ctcController = TextEditingController();
  // Compliance Toggles (Matching React state)
  Map<String, dynamic> _compliances = {
    "pfEmployee": {
      "enabled": true,
      "includedInCTC": false,
      "type": "Limit ₹1,800"
    },
    "pfEmployer": {
      "enabled": true,
      "includedInCTC": true,
      "type": "Limit ₹1,800"
    },
    "esiEmployee": {
      "enabled": true,
      "includedInCTC": false,
      "type": "Statutory (0.75%)"
    },
    "esiEmployer": {
      "enabled": true,
      "includedInCTC": true,
      "type": "Statutory (3.25%)"
    },
    "professionalTax": {
      "enabled": true,
      "includedInCTC": false,
      "type": "Slab Based"
    },
    // ADD THESE MISSING KEYS
    "lwf": {"enabled": false, "includedInCTC": true, "type": "Not Selected"},
    "pt": {"enabled": false, "includedInCTC": false, "type": "Not Selected"},
  };

  String _selectedPFType = "None"; // "None", "₹1800 Limit", "12.0% Variable"
  String _selectedESIType = "None"; // "None", "3.25% Variable"
  String _selectedLWFState = "Not Selected";

// Sub-checkbox states for PF/ESI
  bool _pfIncentive = false;
  bool _pfOvertime = false;
  bool _esiIncentive = false;
  bool _esiOvertime = false;
  bool _pfEdliEnabled = true;

  String _empPFType = "None"; // None, ₹1800 Limit, 12.0% Variable
  String _empESIType = "None"; // None, 0.75% Variable
  String _selectedPTState = "Not Selected";
  String _selectedEmpLWFState = "Not Selected";

// Track which earnings are checked for PF/ESI calculations
// Defaulting standard ones to true
  Map<String, bool> _pfEarningsSelection = {
    "Basic": true,
    "Incentive": false,
    "Overtime": false
  };
  Map<String, bool> _esiEarningsSelection = {
    "Basic": true,
    "Incentive": false,
    "Overtime": false
  };

  // Track Employer-side selections
  Map<String, bool> _employerPfEarningsSelection = {
    "Basic": true,
    "Incentive": false,
    "Overtime": false
  };
  Map<String, bool> _employerEsiEarningsSelection = {
    "Basic": true,
    "Incentive": false,
    "Overtime": false
  };

  final List<String> _masterAllowances = [
    "Dearness Allowance",
    "HRA",
    "Travel Allowance",
    "Special Allowance"
  ];

  final List<String> _allStates = [
    "Not Selected",
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman and Nicobar Island",
    "Chandigarh",
    "Dadra and Nagar Haveli",
    "Daman and Diu",
    "Delhi",
    "Jammu and Kashmir",
    "Puducherry",
    "Ladakh"
  ];

  Map<String, double> _getLWFAmounts(String state) {
    switch (state) {
      case "Andhra Pradesh":
        return {"empr": 5.83, "emp": 2.50};
      case "Chhattisgarh":
        return {"empr": 7.50, "emp": 2.50};
      case "Goa":
        return {"empr": 30.00, "emp": 10.00};
      case "Gujarat":
        return {"empr": 2.00, "emp": 1.00};
      case "Haryana":
        return {"empr": 68.00, "emp": 34.00};
      case "Karnataka":
        return {"empr": 3.33, "emp": 1.67};
      case "Kerala":
        return {"empr": 50.00, "emp": 50.00};
      case "Madhya Pradesh":
        return {"empr": 5.00, "emp": 1.67};
      case "Maharashtra":
        return {"empr": 12.50, "emp": 4.17};
      case "Odisha":
        return {"empr": 3.33, "emp": 1.67};
      case "Punjab":
        return {"empr": 20.00, "emp": 5.00};
      case "Tamil Nadu":
        return {"empr": 3.33, "emp": 1.67};
      case "Telangana":
        return {"empr": 0.42, "emp": 0.17};
      case "West Bengal":
        return {"empr": 2.50, "emp": 0.50};
      case "Chandigarh":
        return {"empr": 20.00, "emp": 5.00};
      case "Delhi":
        return {"empr": 0.38, "emp": 0.13};
      default:
        return {"empr": 0.00, "emp": 0.00};
    }
  }

// Helper to check if an allowance exists in current list
  bool _isAllowanceSelected(String name) =>
      _earnings.any((e) => e['head'] == name);

  // Theme
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Map<String, double> _calculate() {
    // 1. Sum up all Earnings from Breakdown (Basic, HRA, etc.)
    double earningsTotal =
        _earnings.fold(0, (sum, item) => sum + (item['amount'] ?? 0));

    // 2. Sum up all Manual Deductions
    double deductionsTotal =
        _deductions.fold(0, (sum, item) => sum + (item['amount'] ?? 0));

    // 3. PF Employer Logic
    bool pfEnabled = _selectedPFType != "None";
    bool pfEmprIncluded = _compliances['pfEmployer']?['includedInCTC'] ?? false;
    // We only take the 1800 if it is checked for inclusion
    double pfEmprAmount = (pfEnabled && pfEmprIncluded) ? 1800.0 : 0.0;

    // Admin Charges Logic
    // Only add if parent PF is enabled AND Admin checkbox is ticked AND Inclusion is ticked
    double adminCharges =
        (pfEnabled && _pfEdliEnabled && pfEmprIncluded) ? 150.0 : 0.0;

    // 4. LWF Employer Logic
    var lwfData = _getLWFAmounts(_selectedLWFState);
    bool lwfIncluded = _compliances['lwf']?['includedInCTC'] ?? false;
    double currentLwfEmpr = (lwfIncluded && _selectedLWFState != "Not Selected")
        ? (lwfData['empr'] ?? 0.0)
        : 0.0;

    // 5. Final CTC and Gross Calculation
    // CTC and Gross should be the same based on your requirement
    double finalCalculatedTotal =
        earningsTotal + pfEmprAmount + adminCharges + currentLwfEmpr;

    if (_salaryStructure == "Custom") {
      _ctcAmount = finalCalculatedTotal;
      String newText = _ctcAmount.toStringAsFixed(2);
      if (_ctcController.text != newText) {
        _ctcController.text = newText;
      }
    }

    // 6. Net Take Home
    // Strictly Earnings - Manual Deductions
    double netSalary = earningsTotal - deductionsTotal;

    return {
      "gross": finalCalculatedTotal, // Matches CTC logic exactly
      "net": netSalary,
      "deductions": deductionsTotal,
      "ctc": _ctcAmount,
    };
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";

      final results = await Future.wait([
        _salaryApi.getSalaryDetails(widget.employeeId),
        _templateApi.getSalaryTemplates(companyId),
      ]);

      final data = results[0] as Map<String, dynamic>;
      _templates = results[1] as List<SalaryTemplate>;

      if (data.isNotEmpty) {
        setState(() {
          _salaryType = data['salaryType'] ?? "Per Month";
          _salaryStructure = data['salaryStructure'] ?? "Custom";
          _ctcAmount = (data['CTCAmount'] ?? 0).toDouble();
          _earnings = (data['earnings'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _deductions = (data['deductions'] as List)
              .map((d) => Map<String, dynamic>.from(d))
              .toList();
          if (data['compliances'] != null) _compliances = data['compliances'];
          if (data['effectiveMonthOfChange'] != null) {
            _effectiveDate =
                "${data['effectiveMonthOfChange']['year']}-${data['effectiveMonthOfChange']['month'].toString().padLeft(2, '0')}";
          }
          _calculate();
        });
      }
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- CALCULATION LOGIC (Ported from TSX) ---
  // Map<String, double> _calculate() {
  //   double earningsTotal =
  //       _earnings.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
  //   double deductionsTotal =
  //       _deductions.fold(0, (sum, item) => sum + (item['amount'] ?? 0));

  //   const double pfCeiling = 15000;
  //   const double esiThreshold = 21000;

  //   double pfWage = earningsTotal;
  //   if (_compliances['pfEmployee']['type'] == "Limit ₹1,800")
  //     pfWage = earningsTotal > pfCeiling ? pfCeiling : earningsTotal;

  //   double pfEmp = _compliances['pfEmployee']['enabled'] ? (pfWage * 0.12) : 0;
  //   double pfEmpr = _compliances['pfEmployer']['enabled'] ? (pfWage * 0.12) : 0;
  //   double esiEmp = (_compliances['esiEmployee']['enabled'] &&
  //           earningsTotal <= esiThreshold)
  //       ? (earningsTotal * 0.0075)
  //       : 0;
  //   double esiEmpr = (_compliances['esiEmployer']['enabled'] &&
  //           earningsTotal <= esiThreshold)
  //       ? (earningsTotal * 0.0325)
  //       : 0;
  //   double pt = _compliances['professionalTax']['enabled']
  //       ? (earningsTotal > 20000 ? 200 : (earningsTotal > 15000 ? 150 : 0))
  //       : 0;

  //   double totalComplianceEmp = pfEmp + esiEmp + pt;
  //   double employerRecovery =
  //       ((_compliances['pfEmployer']['includedInCTC'] ? pfEmpr : 0) +
  //           (_compliances['esiEmployer']['includedInCTC'] ? esiEmpr : 0));

  //   double netSalary = earningsTotal -
  //       (deductionsTotal + totalComplianceEmp + employerRecovery);

  //   return {
  //     "gross": earningsTotal,
  //     "net": netSalary,
  //     "deductions": deductionsTotal + totalComplianceEmp + employerRecovery,
  //   };
  // }

  Future<void> _updateSalary() async {
    setState(() => _isSaving = true);
    try {
      final dateParts = _effectiveDate.split("-");
      String finalStructure = _salaryStructure;
      if (_salaryType != "Per Month") {
        finalStructure = "Sambalam Provided";
      }
      final payload = {
        "effectiveMonthOfChange": {
          "year": int.parse(dateParts[0]),
          "month": int.parse(dateParts[1])
        },
        "salaryType": _salaryType,
        "salaryStructure": finalStructure,
        "CTCAmount": _ctcAmount,
        "earnings": _salaryType == "Per Month"
            ? _earnings
                .map((e) => {
                      "head": e['head'] ?? e['name'],
                      "calculation": e['calculation'],
                      "amount": e['amount']
                    })
                .toList()
            : [], // Clear if not Monthly
        "deductions": _salaryType == "Per Month"
            ? _deductions
                .map((d) => {
                      "head": d['head'] ?? d['name'],
                      "calculation": d['calculation'],
                      "amount": d['amount']
                    })
                .toList()
            : [], // Clear if not Monthly
        "compliances": _compliances,
      };
      await _salaryApi.updateSalaryDetails(widget.employeeId, payload);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Salary Updated Successfully"),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cal = _calculate();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Edit Salary for ${widget.staffName}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [primaryDeepTeal, secondaryTeal]))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryDeepTeal))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        if (_salaryType == "Per Month") ...[
                          const SizedBox(height: 20),
                          _buildSectionTitle("Earnings / Breakdown"),
                          _buildEarningsList(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Employer Contribution"),
                          _buildEmployerContributionSection(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("Deductions & Compliance"),
                          _buildComplianceSection(),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildBottomSummary(cal),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    bool isCustom = _salaryStructure == "Custom";
    // Determine the suffix based on selection
    String unitLabel = _salaryType == "Per Day"
        ? "/day"
        : (_salaryType == "Per Hour" ? "/hour" : "/month");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelValue("Select Month", _effectiveDate, Icons.calendar_month,
              onTap: _pickMonth),
          const SizedBox(height: 20),
          const Text("Salary Type",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Per Month", "Per Day", "Per Hour"].map((type) {
              bool isSel = _salaryType == type;
              return GestureDetector(
                onTap: () => setState(() {
                  _salaryType = type;
                  // Automatically switch structure to "Sambalam Provided" if not Monthly
                  if (type != "Per Month") {
                    _salaryStructure = "Sambalam Provided";
                  }
                }),
                child: Row(
                  children: [
                    Icon(
                        isSel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSel ? secondaryTeal : Colors.grey,
                        size: 20),
                    const SizedBox(width: 4),
                    Text(type,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              );
            }).toList(),
          ),
          const Divider(height: 32),
          // Structure dropdown only needed for Monthly
          if (_salaryType == "Per Month") ...[
            _buildDropdown(
                "Salary Structure",
                [
                  "Custom",
                  "Sambalam Provided",
                  ..._templates.map((t) => t.name)
                ],
                _salaryStructure,
                (v) => setState(() => _salaryStructure = v!)),
            // ADD THE "ADD NEW TEMPLATE" BUTTON HERE
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const ManageSalaryTemplateScreen(),
                        ),
                      )
                      .then((_) =>
                          _loadData()); // Refresh templates when coming back
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Add new template",
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: secondaryTeal,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildAmountInput(
            "CTC Amount",
            _ctcAmount,
            unitLabel,
            (v) => setState(() => _ctcAmount = double.tryParse(v) ?? 0.0),
            enabled: !isCustom,
            fieldKey: "main_ctc_field",
            controller: _ctcController,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsList() {
    var basicEntry = _earnings.firstWhere((e) => e['head'] == "Basic",
        orElse: () => {"amount": 0.0});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text("Earnings",
        //     style: TextStyle(
        //         fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildBreakdownField("Basic", "basic",
                  currentAmount: (basicEntry['amount'] ?? 0.0).toDouble()),
              // _buildBreakdownField("HRA", "hra"),
              // _buildBreakdownField("Travel Allowance", "travel",
              //     hasFixed: true, hasDelete: true),
              // _buildBreakdownField("Special Allowance", "special",
              //     hasFixed: true, hasDelete: true),
              ..._earnings.where((e) => e['head'] != "Basic").map((e) {
                return _buildBreakdownField(
                  e['head'],
                  e['head'],
                  hasFixed: e['head'] != "HRA",
                  hasDelete: true,
                  currentAmount: (e['amount'] ?? 0).toDouble(),
                  isFixed: e['isFixed'] ?? false,
                );
              }).toList(),
              TextButton.icon(
                onPressed: _showAddAllowanceSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Allowances"),
                style: TextButton.styleFrom(foregroundColor: secondaryTeal),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownField(String label, String key,
      {bool hasFixed = false,
      bool hasDelete = false,
      double currentAmount = 0.0,
      bool isFixed = false}) {
    int idx = _earnings.indexWhere((e) => e['head'] == label);
    double valueToDisplay = (idx != -1)
        ? (_earnings[idx]['amount'] ?? 0.0).toDouble()
        : currentAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildAmountInput(
                "",
                valueToDisplay, // Use the resolved value
                "/month",
                (v) {
                  double parsedValue = double.tryParse(v) ?? 0.0;
                  setState(() {
                    if (idx != -1) {
                      _earnings[idx]['amount'] = parsedValue;
                    } else {
                      // If typing in a field not yet in the list, add it
                      _earnings.add({
                        "head": label,
                        "amount": parsedValue,
                        "calculation": "Flat Rate"
                      });
                    }
                  });
                },
                showLabel: false,
                // CRITICAL: Adding the value to the key forces a refresh when data loads
                fieldKey: "$key-$valueToDisplay",
              ),
            ),
            if (hasDelete)
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => setState(
                      () => _earnings.removeWhere((e) => e['head'] == label))),
          ],
        ),
        if (hasFixed)
          Row(
            children: [
              Checkbox(
                  value: isFixed,
                  onChanged: (v) {
                    if (idx != -1)
                      setState(() => _earnings[idx]['isFixed'] = v);
                  },
                  activeColor: secondaryTeal,
                  visualDensity: VisualDensity.compact),
              const Text("Fixed", style: TextStyle(fontSize: 12)),
            ],
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmployerContributionSection() {
    bool pfEnabled = _selectedPFType != "None";
    bool esiEnabled = _selectedESIType != "None";
    bool lwfEnabled = _selectedLWFState != "Not Selected";
    double pfDisplayAmount = _selectedPFType == "₹1800 Limit" ? 1800.00 : 0.00;
    double edliDisplayAmount = (pfEnabled && _pfEdliEnabled) ? 150.00 : 0.00;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildManageTile(
            "Employer PF",
            _selectedPFType,
            () => _showPFESIModal("PF", isEmployer: true),
            // FORCE display 1800 if selected, else 0
            customDisplayAmount:
                _selectedPFType == "₹1800 Limit" ? 1800.00 : 0.00,
          ),
          _buildIncludedInCTC("pfEmployer", pfEnabled),
          _buildCheckboxRow("PF EDLI & Admin Charges", pfEnabled,
              _pfEdliEnabled, (v) => setState(() => _pfEdliEnabled = v!),
              displayAmount: edliDisplayAmount),

          const Divider(height: 32),

          _buildManageTile("Employer ESI", _selectedESIType,
              () => _showPFESIModal("ESI", isEmployer: true)),
          _buildIncludedInCTC("esiEmployer", esiEnabled),

          const Divider(height: 32),

          // FIXED: Correct Title and correct identifier "LWF_EMPR"
          _buildManageTile(
            "Labour Welfare Fund",
            _selectedLWFState,
            () => _showStatePicker("LWF_EMPR"),
            isEmployerSide:
                true, // This ensures it shows ₹ 5.83 for Andhra Pradesh
          ),
          _buildIncludedInCTC("lwf", lwfEnabled),
        ],
      ),
    );
  }

  Widget _buildManageTile(String title, String currentVal, VoidCallback onTap,
      {bool isEmployerSide = false, double? customDisplayAmount}) {
    double displayAmount = 0.0;

    if (customDisplayAmount != null) {
      displayAmount = customDisplayAmount;
    } else if (currentVal != "Not Selected") {
      var amounts = _getLWFAmounts(currentVal);
      displayAmount = isEmployerSide ? amounts["empr"]! : amounts["emp"]!;
    }
    bool isProfessionalTax = title.contains("Professional Tax");

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title:
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(currentVal,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!isProfessionalTax)
          Text("₹ ${displayAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        const Icon(Icons.arrow_drop_down)
      ]),
      onTap: onTap,
    );
  }

  void _showPFESIModal(String mode, {bool isEmployer = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        // Determine variables based on mode and role
        String currentType;
        Map<String, bool> selectionMap;
        List<String> options;

        if (isEmployer) {
          currentType = (mode == "PF") ? _selectedPFType : _selectedESIType;
          selectionMap = (mode == "PF")
              ? _employerPfEarningsSelection
              : _employerEsiEarningsSelection;
          options = (mode == "PF")
              ? ["None", "₹1800 Limit", "12.0% Variable"]
              : ["None", "3.25% Variable"];
        } else {
          currentType = (mode == "PF") ? _empPFType : _empESIType;
          selectionMap =
              (mode == "PF") ? _pfEarningsSelection : _esiEarningsSelection;
          options = (mode == "PF")
              ? ["None", "₹1800 Limit", "12.0% Variable"]
              : ["None", "0.75% Variable"];
        }

        // Sync earnings list to checkboxes
        for (var e in _earnings) {
          selectionMap.putIfAbsent(e['head'], () => true);
        }

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Manage $mode (${isEmployer ? 'Employer' : 'Employee'})",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...options
                  .map((opt) => Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(opt),
                            value: opt,
                            groupValue:
                                currentType, // Correctly linked to dynamic variable
                            activeColor: secondaryTeal,
                            onChanged: (val) {
                              setState(() {
                                // Updates Parent State
                                if (isEmployer) {
                                  if (mode == "PF")
                                    _selectedPFType = val!;
                                  else
                                    _selectedESIType = val!;
                                } else {
                                  if (mode == "PF")
                                    _empPFType = val!;
                                  else
                                    _empESIType = val!;
                                }
                              });
                              setModalState(() {}); // Updates Modal UI
                            },
                          ),
                          if (opt != "None" && currentType == opt)
                            Padding(
                              padding: const EdgeInsets.only(left: 60),
                              child: Column(
                                children: [
                                  _subOptionCheckbox("BASIC", true, null),
                                  _subOptionCheckbox("Incentive",
                                      selectionMap["Incentive"] ?? false, (v) {
                                    setState(
                                        () => selectionMap["Incentive"] = v!);
                                    setModalState(() {});
                                  }),
                                  _subOptionCheckbox("Overtime",
                                      selectionMap["Overtime"] ?? false, (v) {
                                    setState(
                                        () => selectionMap["Overtime"] = v!);
                                    setModalState(() {});
                                  }),
                                  // Map HRA, Travel, and Custom heads from Earnings
                                  ..._earnings
                                      .where((e) => e['head'] != "Basic")
                                      .map((e) {
                                    String head = e['head'];
                                    return _subOptionCheckbox(
                                        head, selectionMap[head] ?? true, (v) {
                                      setState(() => selectionMap[head] = v!);
                                      setModalState(() {});
                                    });
                                  }).toList(),
                                ],
                              ),
                            )
                        ],
                      ))
                  .toList(),
              const SizedBox(height: 20),
              _modalSaveButton(() => Navigator.pop(context)),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _subOptionCheckbox(
      String label, bool value, Function(bool?)? onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: secondaryTeal,
          // If onChanged is null, it looks prefilled but disabled
          checkColor: onChanged == null ? Colors.white : null,
        ),
        Text(label,
            style: TextStyle(
                color: onChanged == null ? Colors.grey : Colors.black87,
                fontSize: 13)),
      ],
    );
  }

  void _showLWFModal() {
    final List<String> states = [
      "Not Selected",
      "Andhra Pradesh",
      "Assam",
      "Bihar",
      "Goa",
      "Gujarat",
      "Haryana",
      "Karnataka",
      "Kerala",
      "Tamil Nadu",
      "Telangana"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Labour Welfare Fund",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Select State",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: states
                      .map((s) => RadioListTile<String>(
                            title: Text(s),
                            value: s,
                            groupValue: _selectedLWFState,
                            activeColor: secondaryTeal,
                            onChanged: (val) {
                              setState(() => _selectedLWFState = val!);
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildComplianceDropdown(String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: "Not Selected",
                isExpanded: true,
                items: ["Not Selected", "Statutory"]
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) {},
              ),
            ),
            const SizedBox(width: 20),
            const Text("₹ 0.00", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildIncludedInCTC(String key, bool enabled) {
    // Use ?. and ?? false to handle null objects safely
    bool value = _compliances[key]?['includedInCTC'] ?? false;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Checkbox(
              value: value,
              onChanged: enabled
                  ? (v) =>
                      setState(() => _compliances[key]['includedInCTC'] = v)
                  : null,
              activeColor: secondaryTeal,
              visualDensity: VisualDensity.compact),
          const Text("Included in CTC Amount",
              style: TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String label, bool parentEnabled, bool value,
      ValueChanged<bool?> onChanged,
      {double displayAmount = 0.0}) {
    return Opacity(
      opacity: parentEnabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Checkbox(
              value: parentEnabled
                  ? value
                  : false, // Logic: if parent enabled, this is usually checked
              onChanged: parentEnabled ? onChanged : null,
              activeColor: secondaryTeal,
              visualDensity: VisualDensity.compact),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text("₹ ${displayAmount.toStringAsFixed(2)}", // Show the 150.00 here
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComplianceSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildManageTile("Employee PF", _empPFType,
              () => _showManageDeductionModal("Employee PF")),
          _buildManageTile("Employee ESI", _empESIType,
              () => _showManageDeductionModal("Employee ESI")),
          _buildManageTile("Professional Tax", _selectedPTState,
              () => _showStatePicker("PT")),
          // FIXED: Correct identifier "LWF_EMP"
          _buildManageTile(
            "Labour Welfare Fund",
            _selectedEmpLWFState,
            () => _showStatePicker("LWF_EMP"),
            isEmployerSide:
                false, // This ensures it shows ₹ 2.50 for Andhra Pradesh
          ),

          ..._deductions.asMap().entries.map((entry) {
            int idx = entry.key;
            var d = entry.value;
            return ListTile(
              title: Text(d['head'], style: const TextStyle(fontSize: 14)),
              subtitle: Text("₹${d['amount']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: () => setState(() => _deductions.removeAt(idx)),
              ),
            );
          }).toList(),

          TextButton.icon(
            onPressed: _showAddDeductionSheet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Deductions"),
            style: TextButton.styleFrom(foregroundColor: secondaryTeal),
          )
        ],
      ),
    );
  }

  void _showManageDeductionModal(String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        bool isPF = title == "Employee PF";
        // Point to global variables
        String currentType = isPF ? _empPFType : _empESIType;
        Map<String, bool> selectionMap =
            isPF ? _pfEarningsSelection : _esiEarningsSelection;

        List<String> options = isPF
            ? ["None", "₹1800 Limit", "12.0% Variable"]
            : ["None", "0.75% Variable"];

        // Sync earnings to map
        for (var e in _earnings) {
          selectionMap.putIfAbsent(e['head'], () => true);
        }

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Manage $title",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...options
                  .map((opt) => Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(opt),
                            value: opt,
                            groupValue: currentType,
                            activeColor: secondaryTeal,
                            onChanged: (val) {
                              // Update both global state and modal local state
                              setState(() {
                                if (isPF)
                                  _empPFType = val!;
                                else
                                  _empESIType = val!;
                              });
                              setModalState(() {});
                            },
                          ),
                          if (opt != "None" && currentType == opt)
                            Padding(
                              padding: const EdgeInsets.only(left: 60),
                              child: Column(
                                children: [
                                  _subOptionCheckbox("BASIC", true, null),
                                  _subOptionCheckbox("Incentive",
                                      selectionMap["Incentive"] ?? false, (v) {
                                    setState(
                                        () => selectionMap["Incentive"] = v!);
                                    setModalState(() {});
                                  }),
                                  _subOptionCheckbox("Overtime",
                                      selectionMap["Overtime"] ?? false, (v) {
                                    setState(
                                        () => selectionMap["Overtime"] = v!);
                                    setModalState(() {});
                                  }),
                                  ..._earnings
                                      .where((e) => e['head'] != "Basic")
                                      .map((e) {
                                    String head = e['head'];
                                    return _subOptionCheckbox(
                                        head, selectionMap[head] ?? true, (v) {
                                      setState(() => selectionMap[head] = v!);
                                      setModalState(() {});
                                    });
                                  }).toList(),
                                ],
                              ),
                            )
                        ],
                      ))
                  .toList(),
              const SizedBox(height: 20),
              _modalSaveButton(() => Navigator.pop(context)),
            ],
          ),
        );
      }),
    );
  }

  void _showStatePicker(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        // Determine current selection for UI highlighting
        String currentSelection;
        if (type == "PT") {
          currentSelection = _selectedPTState;
        } else if (type == "LWF_EMP") {
          currentSelection = _selectedEmpLWFState;
        } else {
          currentSelection = _selectedLWFState; // LWF_EMPR
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                type == "PT"
                    ? "Professional Tax State"
                    : "Labour Welfare Fund State",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _allStates.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final stateName = _allStates[index];
                    final isSelected = currentSelection == stateName;

                    return RadioListTile<String>(
                      title: Text(stateName,
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  isSelected ? primaryDeepTeal : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      value: stateName,
                      groupValue: currentSelection,
                      activeColor: secondaryTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          final String selectedState = val!;
                          final bool isNotSelected =
                              selectedState == "Not Selected";

                          // Get the statutory amounts for the state being picked
                          var lwfData = _getLWFAmounts(selectedState);

                          // 1. Always sync both LWF fields (Employer and Employee)
                          _selectedLWFState = selectedState;
                          _selectedEmpLWFState = selectedState;

                          // Update internal LWF map with amounts and enabled status
                          _compliances['lwf'] ??= {
                            "enabled": false,
                            "includedInCTC": true,
                            "type": "Not Selected"
                          };
                          _compliances['lwf']['type'] = selectedState;
                          _compliances['lwf']['enabled'] = !isNotSelected;
                          _compliances['lwf']['amount'] =
                              lwfData["empr"]; // Update Employer Amount

                          // 2. Logic for Professional Tax Sync
                          if (type == "PT") {
                            // If user is specifically picking for PT, update all three
                            _selectedPTState = selectedState;
                          } else {
                            // If picking from LWF dropdowns:
                            // Update PT ONLY if it's already active (Not Selected check)
                            if (_selectedPTState != "Not Selected") {
                              _selectedPTState = selectedState;
                            }
                            // Otherwise, _selectedPTState remains "Not Selected"
                          }

                          // 3. Sync the PT Compliance objects based on the resulting _selectedPTState
                          _compliances['pt'] ??= {
                            "enabled": false,
                            "includedInCTC": false,
                            "type": "Not Selected"
                          };
                          _compliances['pt']['type'] = _selectedPTState;
                          _compliances['pt']['enabled'] =
                              _selectedPTState != "Not Selected";

                          // Fetch amounts based on whatever _selectedPTState resulted in
                          var ptData = _getLWFAmounts(_selectedPTState);
                          _compliances['pt']['amount'] =
                              ptData["emp"]; // Update Deduction Amount

                          // Sync the employee-side professionalTax object for statutory rules
                          _compliances['professionalTax'] ??= {
                            "enabled": true,
                            "includedInCTC": false,
                            "type": "Slab Based"
                          };
                          _compliances['professionalTax']['enabled'] =
                              _selectedPTState != "Not Selected";
                        });

                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showAddDeductionSheet() {
    String name = "";
    double amount = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Custom Deduction",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                  labelText: "Deduction Name", border: OutlineInputBorder()),
              onChanged: (v) => name = v,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixText: "₹ ",
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => amount = double.tryParse(v) ?? 0.0,
            ),
            const SizedBox(height: 20),
            _modalSaveButton(() {
              if (name.isNotEmpty) {
                setState(() {
                  _deductions.add({
                    "head": name,
                    "amount": amount,
                    "calculation": "Flat Rate"
                  });
                });
              }
              Navigator.pop(context);
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceRow(String title, String key, {bool showCTC = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          if (showCTC) ...[
            const Text("In CTC",
                style: TextStyle(fontSize: 10, color: Colors.grey)),
            Switch(
              value: _compliances[key]['includedInCTC'],
              activeColor: secondaryTeal,
              onChanged: (v) =>
                  setState(() => _compliances[key]['includedInCTC'] = v),
            ),
          ],
          Checkbox(
            value: _compliances[key]['enabled'],
            activeColor: secondaryTeal,
            onChanged: (v) => setState(() => _compliances[key]['enabled'] = v),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(Map<String, double> cal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem("Gross", cal['gross']!),
                _summaryItem("Deductions", cal['deductions']!, isRed: true),
                _summaryItem("Net Take Home", cal['net']!, isBold: true),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateSalary,
                style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update Salary",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey)));

  Widget _buildLabelValue(String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(icon, size: 16, color: primaryDeepTeal),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
        ]),
      ]),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: onChanged),
    ]);
  }

  Widget _buildAmountInput(
      String label, double value, String unit, Function(String) onChanged,
      {bool enabled = true,
      bool showLabel = true,
      String fieldKey = "",
      TextEditingController? controller}) {
    // Added fieldKey

    return TextFormField(
      // Switched to TextFormField for better state handling
      key: Key(label + fieldKey), // Use the passed fieldKey string
      enabled: enabled,
      controller: controller,
      initialValue: controller == null
          ? (value == 0 ? "" : value.toStringAsFixed(2))
          : null, // Use initialValue instead of controller
      decoration: InputDecoration(
        labelText: showLabel ? label : null,
        prefixText: "₹ ",
        suffixText: unit,
        suffixStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        border: const OutlineInputBorder(),
        fillColor: enabled ? Colors.white : Colors.grey[100],
        filled: !enabled,
        focusedBorder:
            OutlineInputBorder(borderSide: BorderSide(color: secondaryTeal)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
    );
  }

  Widget _summaryItem(String label, double val,
      {bool isRed = false, bool isBold = false}) {
    String unit = _salaryType == "Per Day"
        ? "/day"
        : (_salaryType == "Per Hour" ? "/hour" : "/month");
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text("₹${val.toStringAsFixed(0)} $unit", // Added unit here
          style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: isRed
                  ? Colors.red
                  : (isBold ? secondaryTeal : Colors.black))),
    ]);
  }

  void _pickMonth() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime.parse("$_effectiveDate-01");

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MonthPickerSheet(
        initialMonth: initialDate,
        // Range logic: 2020 to Now + 1 Year
        startYear: 2020,
        endYear: now.year + 1,
      ),
    );

    if (picked != null) {
      setState(() {
        _effectiveDate = DateFormat('yyyy-MM').format(picked);
      });
    }
  }

  void _showAddAllowanceSheet() {
    bool isCustomMode = false;
    String customName = "";
    double customAmount = 0.0;
    bool customFixed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isCustomMode ? "Add Allowances" : "Add Allowances",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () =>
                        setModalState(() => isCustomMode = !isCustomMode),
                    child: Text(isCustomMode ? "Select Items" : "Add Custom",
                        style: TextStyle(
                            color: secondaryTeal, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 20),
              if (!isCustomMode) ...[
                // PRE-DEFINED LIST VIEW
                ..._masterAllowances.map((name) {
                  bool isSelected = _isAllowanceSelected(name);
                  return CheckboxListTile(
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    value: isSelected,
                    activeColor: secondaryTeal,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _earnings.add({
                            "head": name,
                            "amount": 0.0,
                            "calculation": "Flat Rate",
                            "isFixed": false
                          });
                        } else {
                          _earnings.removeWhere((e) => e['head'] == name);
                        }
                      });
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ] else ...[
                // CUSTOM ADDITION VIEW
                TextField(
                  decoration: const InputDecoration(
                      labelText: "Name", border: OutlineInputBorder()),
                  onChanged: (v) => customName = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                      labelText: "Amount",
                      prefixText: "₹ ",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => customAmount = double.tryParse(v) ?? 0.0,
                ),
                if (customName.toUpperCase() != "HRA")
                  CheckboxListTile(
                    title: const Text("Fixed", style: TextStyle(fontSize: 14)),
                    value: customFixed,
                    onChanged: (v) => setModalState(() => customFixed = v!),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryTeal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    if (isCustomMode && customName.isNotEmpty) {
                      setState(() {
                        _earnings.add({
                          "head": customName,
                          "amount": customAmount,
                          "calculation":
                              customFixed ? "Flat Rate" : "On Attendance",
                          "isFixed": customFixed
                        });
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isCustomMode ? "Add Allowance" : "Save",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _modalSaveButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: secondaryTeal,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        onPressed: onPressed,
        child: const Text("Save",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;
  final int startYear;
  final int endYear;

  const _MonthPickerSheet({
    Key? key,
    required this.initialMonth,
    required this.startYear,
    required this.endYear,
  }) : super(key: key);

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF206C5E);
    final List<int> years = List.generate(
      (widget.endYear - widget.startYear) + 1,
      (index) => widget.startYear + index,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Select Year',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedYear,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: years
                .map((y) =>
                    DropdownMenuItem(value: y, child: Text(y.toString())))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedYear = val);
            },
          ),
          const SizedBox(height: 24),
          const Text('Select Month',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthIndex = index + 1;
                final monthName =
                    DateFormat.MMMM().format(DateTime(2022, monthIndex));
                final isSelected = _selectedMonth == monthIndex;

                return InkWell(
                  onTap: () => setState(() => _selectedMonth = monthIndex),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? primaryColor : Colors.black87,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(DateTime(_selectedYear, _selectedMonth, 1));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
