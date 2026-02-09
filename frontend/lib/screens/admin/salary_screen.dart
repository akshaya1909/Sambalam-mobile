import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "../../api/salary_api_service.dart";

class SalaryScreen extends StatefulWidget {
  final String employeeId;
  final String phoneNumber;
  final String companyId;
  final String staffName;
  const SalaryScreen({
    Key? key,
    required this.employeeId,
    required this.phoneNumber,
    required this.companyId,
     required this.staffName}) : super(key: key);

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final SalaryApiService _salaryApi = SalaryApiService();
  // Theme Colors matching Admin Home Screen
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color scaffoldBg = const Color(0xFFF4F6FB);

  bool _isLoading = true;
  Map<String, dynamic>? _salaryConfig;
  String? _employeeId;
  DateTime _selectedMonth = DateTime(2026, 1);

  final Map<String, TextEditingController> _controllers = {
    'Bonus': TextEditingController(text: "0"),
    'Other Earnings': TextEditingController(text: "0"),
    'Work Basis Pay': TextEditingController(text: "0"),
    'Overtime': TextEditingController(text: "0"),
    'Incentive': TextEditingController(text: "0"),
    'Reimbursement': TextEditingController(text: "0"),
    'Loan Repayment': TextEditingController(text: "0"),
    'Early Leaving Fine': TextEditingController(text: "0"),
    'Late Coming Fine': TextEditingController(text: "0"),
    'Other Deductions': TextEditingController(text: "0"),
  };

  double payableDays = 0.0;
double weekOffs = 0.0;
double lossOfPay = 0.0;
double totalWorkingDays = 31.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
  setState(() => _isLoading = true);
  try {
    final dynamicData = await _salaryApi.calculateDynamicPayableDays(
      employeeId: widget.employeeId,
      companyId: widget.companyId,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );

    if (dynamicData['success'] == true) {
      // Fetch the actual salary configuration from your DB
      final salaryConfigData = await _salaryApi.getSalaryDetails(widget.employeeId);

      setState(() {
        payableDays = (dynamicData['payableDays'] as num).toDouble();
        weekOffs = (dynamicData['weekOffs'] as num).toDouble();
        lossOfPay = (dynamicData['lossOfPay'] as num).toDouble();
        totalWorkingDays = (dynamicData['totalDaysInMonth'] as num).toDouble();
        
        // Use real data from DB if available, else fallback to your mock
        _salaryConfig = salaryConfigData.isNotEmpty ? salaryConfigData : {
          "earnings": [
            {"head": "Basic", "amount": 20000},
            {"head": "HRA", "amount": 10000},
            {"head": "Travel Allowance", "amount": 4000},
            {"head": "Special Allowance", "amount": 6000},
          ],
        };
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Salary Fetch Error: $e");
    setState(() => _isLoading = false);
  }
}

  // CALCULATION LOGIC: (Amount / Total Month Days) * Present Days
  double _calculateProRata(double amount) {
    if (totalWorkingDays == 0) return 0;
    return (amount / totalWorkingDays) * payableDays;
  }

  double _getTotalEarnings() {
    double total = 0;
    // DB Earnings
    for (var e in _salaryConfig?['earnings'] ?? []) {
      total += _calculateProRata(double.parse(e['amount'].toString()));
    }
    // Editable Earnings
    total += double.tryParse(_controllers['Bonus']!.text) ?? 0;
    total += double.tryParse(_controllers['Other Earnings']!.text) ?? 0;
    total += double.tryParse(_controllers['Work Basis Pay']!.text) ?? 0;
    total += double.tryParse(_controllers['Overtime']!.text) ?? 0;
    total += double.tryParse(_controllers['Incentive']!.text) ?? 0;
    total += double.tryParse(_controllers['Reimbursement']!.text) ?? 0;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDeepTeal, secondaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Salary Breakdown",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Month Selector & Status Alert
          _buildMonthSelector(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildStatusAlert(),
                  const SizedBox(height: 16),

                  // 2. Main Payable Card
                  _buildPayableCard(),
                  const SizedBox(height: 20),

                  // 3. Earnings Section
                  _buildSectionHeader(
                      "Earnings", Icons.trending_up, Colors.green),
                  _buildSalaryCard([
  // DYNAMIC HEADINGS FROM DB
  if (_salaryConfig != null && _salaryConfig!['earnings'] != null)
    ...(_salaryConfig!['earnings'] as List).map((e) {
      // Define the variables locally inside the map function
      final String currentHead = e['head']?.toString() ?? 'Unknown';
      final double baseAmount = double.tryParse(e['amount'].toString()) ?? 0.0;
      
      // Calculate amount based on: (Base / Month Days) * (Present + WeekOffs + Sundays)
      double calculatedValue = _calculateProRata(baseAmount);
      String formattedAmount = NumberFormat('#,##,###.00').format(calculatedValue);

      return _salaryRow(currentHead, "₹ $formattedAmount");
}).toList(),

  const Divider(height: 1, indent: 16, endIndent: 16),

  // EDITABLE FIELDS
                    _editableSalaryRow("Bonus", _controllers['Bonus']!),
                    _editableSalaryRow("Other Earnings", _controllers['Other Earnings']!),
                    _editableSalaryRow("Work Basis Pay", _controllers['Work Basis Pay']!),
                    _editableSalaryRow("Overtime", _controllers['Overtime']!),
                    _editableSalaryRow("Incentive", _controllers['Incentive']!),
                    _editableSalaryRow("Reimbursement", _controllers['Reimbursement']!),
                  ]),

                  const SizedBox(height: 20),

                  // 4. Deductions Section
                  _buildSectionHeader(
                      "Deductions", Icons.trending_down, Colors.red),
                  _buildSalaryCard([
                    _editableSalaryRow("Loan Repayment", _controllers['Loan Repayment']!, isNegative: true),
                    _editableSalaryRow("Early Leaving Fine", _controllers['Early Leaving Fine']!, isNegative: true),
                    _editableSalaryRow("Late Coming Fine", _controllers['Late Coming Fine']!, isNegative: true),
                    _editableSalaryRow("Other Deductions", _controllers['Other Deductions']!, isNegative: true),
                  ]),

                  const SizedBox(height: 100), // Space for footer
                ],
              ),
            ),
          ),
        ],
      ),
      // 5. Fixed Action Footer
      bottomSheet: _buildActionFooter(),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scaffoldBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM yyyy').format(_selectedMonth),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildStatusAlert() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Calculation is not up to date. Verified on 2 Jan 2026",
              style: TextStyle(
                  color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("Update Now",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          )
        ],
      ),
    );
  }


  Widget _editableSalaryRow(String label, TextEditingController controller, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              onChanged: (v) => setState(() {}),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isNegative ? Colors.red : Colors.black,
              ),
              decoration: const InputDecoration(prefixText: '₹ ', border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildPayableCard() {
    double total = _getTotalEarnings();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text("PAYABLE AMOUNT (Based on $payableDays Days)", 
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
  "₹ ${NumberFormat('#,##,###.00').format(total)}", 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryDeepTeal)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem("Worked", "${payableDays - weekOffs}", Colors.blue),
            _summaryItem("Week Offs", "$weekOffs", Colors.teal),
            _summaryItem("Loss of Pay", "$lossOfPay", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          if (title == "Earnings")
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text("Pay Slip", style: TextStyle(fontSize: 12)),
            )
        ],
      ),
    );
  }

  Widget _buildSalaryCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: rows),
    );
  }

  Widget _salaryRow(String label, String amount, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: secondaryTeal),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("PAY ADVANCE",
                  style: TextStyle(
                      color: primaryDeepTeal, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDeepTeal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("PAY SALARY",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
