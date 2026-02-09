import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/employee_service.dart';

class BackgroundVerificationScreen extends StatefulWidget {
  final String userId;
  final String employeeId;
  final String companyId;

  const BackgroundVerificationScreen({
    Key? key,
    required this.userId,
    required this.employeeId,
    required this.companyId,
  }) : super(key: key);

  @override
  _BackgroundVerificationScreenState createState() =>
      _BackgroundVerificationScreenState();
}

class _BackgroundVerificationScreenState
    extends State<BackgroundVerificationScreen> {
  final EmployeeService _api = EmployeeService();
  bool isLoading = true;
  Map<String, dynamic>? employee;

  // Data Maps - Getters with robust null safety
  Map<String, dynamic> get personal => employee?['personal'] ?? {};
  Map<String, dynamic> get basic => employee?['basic'] ?? {};

  // FIXED: Simplified logic to avoid syntax errors
  Map<String, dynamic> get employment {
    if (employee == null || employee!['employment'] == null) return {};
    final empList = employee!['employment'] as List;
    if (empList.isEmpty) return {};
    return empList[0] as Map<String, dynamic>;
  }

  List<dynamic> get documents => employee?['documents'] ?? [];
  Map<String, dynamic> get verification => employee?['verification'] ?? {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _api.getEmployee(
          widget.employeeId,
          widget
              .companyId); // Note: Make sure getEmployee uses employeeId if fetching specific employee data
      // If widget.userId is actually the admin's ID, and widget.employeeId is the target employee, use widget.employeeId here.
      // Based on previous context, usually you fetch by the target employee ID.
      // Assuming getEmployee takes (id, companyId)

      setState(() {
        employee = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load data")));
    }
  }

  // --- Logic Helpers ---
  dynamic _getDoc(String category) {
    // documents is a List<dynamic>
    try {
      return documents.firstWhere((d) => d['category'] == category,
          orElse: () => null);
    } catch (e) {
      return null;
    }
  }

  String _calcStatus(String? dbStatus, bool hasNum, bool hasDoc) {
    if (dbStatus == 'verified') return 'verified';
    if (hasNum && hasDoc) return 'pending';
    if (hasNum || hasDoc) return 'incomplete';
    return 'not-submitted';
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final items = _buildVerificationItems();
    final verifiedCount = items.where((i) => i['status'] == 'verified').length;
    final pendingCount = items.where((i) => i['status'] == 'pending').length;
    final actionCount = items
        .where((i) => ['not-submitted', 'incomplete'].contains(i['status']))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate-50 equivalent
      appBar: AppBar(
        title: const Text("Background Verification",
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  _buildSummaryCard("Verified", verifiedCount.toString(),
                      Colors.green.shade50, Colors.green.shade700),
                  const SizedBox(width: 8),
                  _buildSummaryCard("Pending", pendingCount.toString(),
                      Colors.blue.shade50, Colors.blue.shade700),
                  const SizedBox(width: 8),
                  _buildSummaryCard("Action", actionCount.toString(),
                      Colors.orange.shade50, Colors.orange.shade700),
                ],
              ),
              const SizedBox(height: 24),

              const Text("Document Status",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // List Items
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  return _buildListItem(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color bg, Color text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: text.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: text)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(fontSize: 12, color: text.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    switch (item['status']) {
      case 'verified':
        badgeBg = Colors.green.shade50;
        badgeText = Colors.green.shade700;
        badgeLabel = "Verified";
        badgeIcon = LucideIcons.checkCircle;
        break;
      case 'pending':
        badgeBg = Colors.blue.shade50;
        badgeText = Colors.blue.shade700;
        badgeLabel = "Pending";
        badgeIcon = LucideIcons.clock;
        break;
      case 'incomplete':
        badgeBg = Colors.orange.shade50;
        badgeText = Colors.orange.shade700;
        badgeLabel = "Incomplete";
        badgeIcon = LucideIcons.alertCircle;
        break;
      default:
        badgeBg = Colors.red.shade50;
        badgeText = Colors.red.shade700;
        badgeLabel = "Not Submitted";
        badgeIcon = LucideIcons.xCircle;
    }

    // Button Logic
    bool showUploadIcon = !item['hasDoc'] && !item['hasNumber'];
    if (item['actionType'] == 'verify_face') showUploadIcon = false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: () => _openBottomSheet(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)),
                child:
                    Icon(item['icon'], color: Colors.grey.shade600, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (item['documentNumber'] != null)
                      Text(item['documentNumber'],
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontFamily: 'Monospace')),

                    const SizedBox(height: 6),
                    // Tiny Indicators
                    if (item['id'] != 'address' &&
                        item['id'] != 'pastEmployment' &&
                        item['actionType'] != 'verify_face' &&
                        item['status'] != 'verified')
                      Row(
                        children: [
                          if (item['actionType'] != 'verify_number')
                            _buildTinyIndicator("File", item['hasDoc']),
                          if (item['actionType'] != 'verify_number')
                            const SizedBox(width: 8),
                          _buildTinyIndicator("Number", item['hasNumber']),
                        ],
                      ),
                    if (item['id'] == 'address' && item['status'] != 'verified')
                      Row(
                        children: [
                          _buildTinyIndicator("Proof", item['hasDoc']),
                          const SizedBox(width: 8),
                          _buildTinyIndicator("Address", item['hasNumber']),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: badgeBg, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeText),
                        const SizedBox(width: 4),
                        Text(badgeLabel,
                            style: TextStyle(
                                color: badgeText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item['actionType'] != 'view_only')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (item['status'] == 'verified')
                            ? Colors.transparent
                            : (item['hasDoc'] || item['hasNumber'])
                                ? Colors.blue.shade600
                                : Colors.white,
                        border: item['status'] == 'verified'
                            ? null
                            : Border.all(color: Colors.blue.shade600),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: item['status'] == 'verified'
                          ? const Icon(LucideIcons.eye,
                              size: 16, color: Colors.grey)
                          : Row(
                              children: [
                                Text(
                                  item['actionType'] == 'verify_face'
                                      ? 'Face'
                                      : (item['hasDoc'] || item['hasNumber'])
                                          ? 'Verify'
                                          : 'Upload',
                                  style: TextStyle(
                                      color:
                                          (item['hasDoc'] || item['hasNumber'])
                                              ? Colors.white
                                              : Colors.blue.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  showUploadIcon
                                      ? LucideIcons.upload
                                      : LucideIcons.chevronRight,
                                  size: 12,
                                  color: (item['hasDoc'] || item['hasNumber'])
                                      ? Colors.white
                                      : Colors.blue.shade600,
                                )
                              ],
                            ),
                    )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTinyIndicator(String label, bool isDone) {
    return Row(
      children: [
        Icon(isDone ? LucideIcons.checkCircle : LucideIcons.xCircle,
            size: 10, color: isDone ? Colors.green : Colors.red),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: isDone ? Colors.green : Colors.red)),
      ],
    );
  }

  // --- Data Generator ---
  List<Map<String, dynamic>> _buildVerificationItems() {
    final docAadhar = _getDoc("Aadhar");
    final docPan = _getDoc("PAN Card");
    final docDL = _getDoc("Driving license");
    final docVoter = _getDoc("Voter ID");
    final docAddress = _getDoc("Address Proof");

    return [
      {
        'id': "aadhar",
        'name': "Aadhaar / SSN",
        'icon': LucideIcons.creditCard,
        'status': _calcStatus(verification['aadhar']?['status'],
            personal['aadharNumber'] != null, docAadhar != null),
        'documentNumber': personal['aadharNumber'],
        'docCategory': "Aadhar",
        'fieldKey': "aadharNumber",
        'docFile': docAadhar,
        'hasDoc': docAadhar != null,
        'hasNumber': personal['aadharNumber'] != null,
      },
      {
        'id': "pan",
        'name': "PAN / Tax ID",
        'icon': LucideIcons.fileText,
        'status': _calcStatus(verification['pan']?['status'],
            personal['panNumber'] != null, docPan != null),
        'documentNumber': personal['panNumber'],
        'docCategory': "PAN Card",
        'fieldKey': "panNumber",
        'docFile': docPan,
        'hasDoc': docPan != null,
        'hasNumber': personal['panNumber'] != null,
      },
      {
        'id': "drivingLicense",
        'name': "Driving License",
        'icon': LucideIcons.car,
        'status': _calcStatus(verification['drivingLicense']?['status'],
            personal['drivingLicenseNumber'] != null, docDL != null),
        'documentNumber': personal['drivingLicenseNumber'],
        'docCategory': "Driving license",
        'fieldKey': "drivingLicenseNumber",
        'docFile': docDL,
        'hasDoc': docDL != null,
        'hasNumber': personal['drivingLicenseNumber'] != null,
      },
      {
        'id': "voterId",
        'name': "Voter ID",
        'icon': LucideIcons.vote,
        'status': _calcStatus(verification['voterId']?['status'],
            personal['voterIdNumber'] != null, docVoter != null),
        'documentNumber': personal['voterIdNumber'],
        'docCategory': "Voter ID",
        'fieldKey': "voterIdNumber",
        'docFile': docVoter,
        'hasDoc': docVoter != null,
        'hasNumber': personal['voterIdNumber'] != null,
      },
      {
        'id': "uan",
        'name': "UAN (PF)",
        'icon': LucideIcons.fileText,
        'status': verification['uan']?['status'] == 'verified'
            ? 'verified'
            : (personal['uanNumber'] != null ? 'pending' : 'not-submitted'),
        'documentNumber': personal['uanNumber'],
        'actionType': "verify_number",
        'fieldKey': "uanNumber",
        'hasDoc': true,
        'hasNumber': personal['uanNumber'] != null,
      },
      {
        'id': "face",
        'name': "Face Verification",
        'icon': LucideIcons.camera,
        'status': verification['face']?['status'] ?? "not-submitted",
        'actionType': "verify_face",
        'hasDoc': true, 'hasNumber': true, // Mock true to enable button
      },
      {
        'id': "address",
        'name': "Address",
        'icon': LucideIcons.mapPin,
        'status': verification['address']?['status'] ?? "not-submitted",
        'docCategory': "Address Proof",
        'docFile': docAddress,
        'hasDoc': docAddress != null,
        'hasNumber': basic['currentAddress'] != null ||
            personal['permanentAddress'] != null,
      },
      {
        'id': "pastEmployment",
        'name': "Past Employment",
        'icon': LucideIcons.briefcase,
        'status': verification['pastEmployment']?['status'] ?? "not-submitted",
        'hasNumber':
            (employment['pastEmployments'] as List?)?.isNotEmpty ?? false,
        'hasDoc': true,
      },
    ];
  }

  // --- BOTTOM SHEET LOGIC ---

  void _openBottomSheet(Map<String, dynamic> item) {
    if (item['actionType'] == 'verify_face') {
      _showFaceVerifyDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => VerificationSheet(
        item: item,
        employeeId: widget.employeeId, // Use the correct ID for operations
        companyId: widget.companyId,
        phone: basic['phone'],
        onUpdate: () {
          Navigator.pop(context);
          _fetchData(); // Refresh main screen
        },
        personal: personal,
        basic: basic,
        employment: employment,
        uanVerified: verification['uan']?['status'] == 'verified',
        hasUan: personal['uanNumber'] != null,
      ),
    );
  }

  void _showFaceVerifyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(child: Text("Face Verification")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                  color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(LucideIcons.scanFace,
                  size: 50, color: Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            const Text("Verify Face to prevent Identity Theft",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            const Text("Identity verification against records.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Face Verification Initiated!")));
              },
              child: const Text("Start Verification"),
            ),
          )
        ],
      ),
    );
  }
}

// --- SEPARATE WIDGET FOR BOTTOM SHEET CONTENT ---

class VerificationSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final String employeeId;
  final String companyId;
  final String? phone;
  final VoidCallback onUpdate;
  final Map<String, dynamic> personal;
  final Map<String, dynamic> basic;
  final Map<String, dynamic> employment;
  final bool uanVerified;
  final bool hasUan;

  const VerificationSheet({
    Key? key,
    required this.item,
    required this.employeeId,
    required this.companyId,
    this.phone,
    required this.onUpdate,
    required this.personal,
    required this.basic,
    required this.employment,
    required this.uanVerified,
    required this.hasUan,
  }) : super(key: key);

  @override
  _VerificationSheetState createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<VerificationSheet> {
  final EmployeeService _api = EmployeeService();
  TextEditingController _numController = TextEditingController();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.item['id'] != 'address' &&
        widget.item['id'] != 'pastEmployment') {
      _numController.text = widget.item['documentNumber'] ?? "";
    }
  }

  // API Callers
  Future<void> _saveNumber() async {
    if (_numController.text.isEmpty) return;
    setState(() => isProcessing = true);
    try {
      await _api.updatePersonalDetails(
          widget.employeeId, {widget.item['fieldKey']: _numController.text});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Details saved!")));
      widget.onUpdate();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to save")));
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['jpg', 'pdf', 'png']);
    if (result != null) {
      setState(() => isProcessing = true);
      try {
        await _api.uploadDocument(widget.employeeId,
            File(result.files.single.path!), widget.item['docCategory']);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Document Uploaded!")));
        widget.onUpdate();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Upload failed")));
      } finally {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _verify() async {
    // Special UAN Check
    if (widget.item['id'] == 'pastEmployment') {
      if (!widget.hasUan) {
        _showUanAlert();
        return;
      }
    }

    setState(() => isProcessing = true);
    try {
      await _api.verifyAttribute(widget.employeeId, widget.item['id']);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verified Successfully!")));
      widget.onUpdate();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Verification failed")));
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showUanAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verify Identity Proofs"),
        content: const Text(
            "Please verify staff's UAN Number to verify Past Employment."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Okay"))
        ],
      ),
    );
  }

  // --- Address Logic Helpers ---
  void _editAddress(String type, String currentVal) {
    TextEditingController addrCtrl = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text("Edit ${type == 'current' ? 'Current' : 'Permanent'} Address"),
        content: TextField(
            controller: addrCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), hintText: "Enter full address")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                if (type == 'permanent') {
                  await _api.updatePersonalDetails(
                      widget.employeeId, {'permanentAddress': addrCtrl.text});
                } else {
                  await _api.updateBasicDetails(widget.employeeId,
                      {'phone': widget.phone, 'currentAddress': addrCtrl.text});
                }
                Navigator.pop(ctx);
                widget.onUpdate();
              } catch (e) {
                print(e);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- Past Employment Logic Helpers ---
  void _editPastEmployment(Map<String, dynamic>? emp, int? index) {
    // Basic Dialog for adding company (Simplified for mobile)
    final nameCtrl = TextEditingController(text: emp?['companyName']);
    final desigCtrl = TextEditingController(text: emp?['designation']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index != null ? "Edit Company" : "Add Company"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Company Name")),
            TextField(
                controller: desigCtrl,
                decoration: const InputDecoration(labelText: "Designation")),
            // Add Date pickers here for a full implementation
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Map<String, dynamic> data = {
                "companyName": nameCtrl.text,
                "designation": desigCtrl.text,
                "currency": "INR", // Default
                // Add dates logic
              };
              // Call API using _api.addPastEmployment wrapper (needs implementing update logic in service similar to React)
              // For simplicity, mimicking add:
              await _api.addPastEmployment(
                  widget.employeeId, widget.phone!, data);
              Navigator.pop(ctx);
              widget.onUpdate();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSidebarEnabled = (item['id'] == 'address')
        ? (item['hasDoc'] && item['hasNumber'])
        : (item['id'] == 'pastEmployment'
            ? item['hasNumber']
            : (item['hasDoc'] && item['hasNumber']));

    return Container(
      padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Verify ${item['name']}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === ADDRESS VIEW ===
                  if (item['id'] == 'address') ...[
                    _buildAddressBox(
                        "Current Address",
                        widget.basic['currentAddress'],
                        () => _editAddress(
                            'current', widget.basic['currentAddress'] ?? "")),
                    const SizedBox(height: 12),
                    _buildAddressBox(
                        "Permanent Address",
                        widget.personal['permanentAddress'],
                        () => _editAddress('permanent',
                            widget.personal['permanentAddress'] ?? "")),
                    const SizedBox(height: 20),
                    _buildDocUploadSection(),
                  ]
                  // === PAST EMPLOYMENT VIEW ===
                  else if (item['id'] == 'pastEmployment') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Past Companies",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        OutlinedButton.icon(
                          onPressed: () => _editPastEmployment(null, null),
                          icon: const Icon(LucideIcons.plus, size: 14),
                          label: const Text("Add"),
                          style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    if ((widget.employment['pastEmployments'] as List?)
                            ?.isNotEmpty ??
                        false)
                      ...(widget.employment['pastEmployments'] as List)
                          .asMap()
                          .entries
                          .map((entry) {
                        int idx = entry.key;
                        var emp = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp['companyName'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(emp['designation'] ?? '',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                  icon:
                                      const Icon(LucideIcons.pencil, size: 16),
                                  onPressed: () =>
                                      _editPastEmployment(emp, idx))
                            ],
                          ),
                        );
                      })
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200)),
                        child: const Text("No past employment details added.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                      )
                  ]
                  // === STANDARD VIEW ===
                  else ...[
                    // Number Input
                    if (item['actionType'] != 'verify_number_only_special') ...[
                      // Adjust logic if needed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item['name']} Number",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Icon(
                              item['hasNumber']
                                  ? LucideIcons.checkCircle
                                  : LucideIcons.xCircle,
                              color:
                                  item['hasNumber'] ? Colors.green : Colors.red,
                              size: 16)
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _numController,
                              decoration: InputDecoration(
                                hintText: "Enter Number",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isProcessing ? null : _saveNumber,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black,
                                elevation: 0),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text("Save"),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Doc Upload
                    if (item['actionType'] != 'verify_number')
                      _buildDocUploadSection(),
                  ]
                ],
              ),
            ),
          ),

          // Verify Button Footer
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: item['status'] == 'verified'
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.checkCircle,
                            color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                            "Verified on ${item['verifiedOn'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['verifiedOn'])) : ''}",
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed:
                        (isSidebarEnabled && !isProcessing) ? _verify : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      disabledBackgroundColor: Colors.blue.shade100,
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            "Verify ${item['id'] == 'address' ? 'Address' : item['name']}"),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildAddressBox(String title, String? address, VoidCallback onEdit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              InkWell(
                onTap: onEdit,
                child: Row(children: [
                  Icon(address != null ? LucideIcons.pencil : LucideIcons.plus,
                      size: 12),
                  SizedBox(width: 4),
                  Text(address != null ? "Edit" : "Add",
                      style: const TextStyle(fontSize: 12))
                ]),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(address ?? "Not Added",
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDocUploadSection() {
    final item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item['docCategory'] ?? "Document Proof",
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Icon(item['hasDoc'] ? LucideIcons.checkCircle : LucideIcons.xCircle,
                color: item['hasDoc'] ? Colors.green : Colors.red, size: 16)
          ],
        ),
        const SizedBox(height: 8),
        if (item['hasDoc'])
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100)),
            child: Row(
              children: [
                const Icon(LucideIcons.fileCheck, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['docFile']['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(item['docFile']['size'],
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(LucideIcons.eye, size: 18),
                    onPressed: () {}) // Open URL logic
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.grey.shade200,
                    style: BorderStyle
                        .solid)), // Use Dotted border package for perfection
            child: const Text("No document uploaded yet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : _uploadFile,
                icon: const Icon(LucideIcons.upload, size: 16),
                label: Text(
                    item['hasDoc'] ? "Replace Document" : "Upload Document"),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        )
      ],
    );
  }
}
