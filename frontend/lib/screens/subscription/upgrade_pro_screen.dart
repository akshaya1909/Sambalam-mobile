import 'package:flutter/material.dart';
import '../../api/plan_api_service.dart';
import '../../api/addon_api_service.dart';

class PricingEngine {
  static double calculateProrationFactor(String? expiryDate) {
    if (expiryDate == null) return 1.0;
    final expiry = DateTime.parse(expiryDate);
    final now = DateTime.now();
    final diff = expiry.difference(now).inDays;
    if (diff <= 0) return 1.0;
    return diff / 365; // Assuming annual cycle
  }

  static int calculateProratedPrice(int price, double factor) {
    double prorated = price * factor;
    return (prorated - prorated.floor() >= 0.5)
        ? prorated.ceil()
        : prorated.floor();
  }
}

class _AddonCounterTile extends StatelessWidget {
  final String label;
  final int value;
  final int price;
  final Function(int) onChanged;

  const _AddonCounterTile(
      {required this.label,
      required this.value,
      required this.price,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("₹$price/yr each",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => onChanged(value > 0 ? value - 1 : 0)),
            Text("$value",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onChanged(value + 1)),
          ])
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isSelected;
  final bool isCurrent;
  final bool isRecommended;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    required this.isRecommended,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final price = plan['price'] ?? 0;
    const Color primaryColor = Color(0xFF206C5E);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // --- Main Card Body ---
        GestureDetector(
          onTap: onSelect,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[200]!,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Plan Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${plan['maxCompanies']} Company • ${plan['maxEmployees']} Employees",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price == 0
                          ? "Free"
                          : "₹${(price as num).toLocaleString('en-IN')}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    if (price > 0)
                      Text(
                        "/year",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // --- Recommended Badge (Top Left) ---
        if (isRecommended)
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Recommended",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // --- Current Plan Badge (Top Right) ---
        if (isCurrent)
          Positioned(
            top: -10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Current Plan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // --- Selection Checkmark ---
        if (isSelected)
          Positioned(
            bottom: 6, // Positioned near bottom right of card
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}

// Extension to handle currency formatting locally
extension CurrencyFormatter on num {
  String toLocaleString(String locale) {
    return toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

class _CRMSwitchTile extends StatelessWidget {
  final bool enabled;
  final int price;
  final Function(bool) onChanged;

  const _CRMSwitchTile(
      {required this.enabled, required this.price, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF206C5E).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.contact_phone_outlined, color: Color(0xFF206C5E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CRM Lite",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("₹$price/yr • Lead management",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: const Color(0xFF206C5E),
          ),
        ],
      ),
    );
  }
}

class UpgradeProScreen extends StatefulWidget {
  final Map<String, dynamic> activePlan;
  const UpgradeProScreen({Key? key, required this.activePlan})
      : super(key: key);

  @override
  State<UpgradeProScreen> createState() => _UpgradeProScreenState();
}

class _UpgradeProScreenState extends State<UpgradeProScreen> {
  int _currentStep = 1;
  String _selectedPlanName = "";
  int _extraCompanies = 0;
  int _extraEmployees = 0;
  bool _crmEnabled = false;

  List<dynamic> _plans = [];
  List<dynamic> _addons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPlanName = widget.activePlan['planName']?.toLowerCase() ?? "free";
    _fetchData();
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      PlanApiService().getAllPlans(),
      AddonApiService().getAllAddons(),
    ]);
    setState(() {
      _plans = results[0];
      _addons = results[1];
      _isLoading = false;
    });
  }

  // --- Logic Computed Properties ---
  bool get isTopUp {
    final String? status = widget.activePlan['status'];
    // If the plan is EXPIRED, it's a full renewal, not a top-up.
    if (status == 'expired') return false;

    return _selectedPlanName == widget.activePlan['planName']?.toLowerCase() &&
        (widget.activePlan['totalAmount'] ?? 0) > 0;
  }

  double get prorationFactor =>
      PricingEngine.calculateProrationFactor(widget.activePlan['expiryDate']);

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        // Match the teal color of the customize button
        backgroundColor: const Color(0xFF206C5E),
        // Ensure the back button and text are white
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _currentStep == 1 ? "Choose Your Plan" : "Customize Plan",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: _currentStep == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => setState(() => _currentStep = 1),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStep1() {
    final crmAddon = _addons.firstWhere(
      (a) => a['label'].toLowerCase().contains("crm"),
      orElse: () => null,
    );

    String priceText = "";
    if (crmAddon != null) {
      final int price = crmAddon['price'] ?? 0;
      // Map billing cycle to duration text (similar to your web duration logic)
      String duration = crmAddon['billingCycle'] == "annual" ? "/yr" : "/mo";
      priceText = "₹${(price as num).toLocaleString('en-IN')}$duration";
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select the plan that best fits your business needs.",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Dynamic Plan Listing
        ..._plans.map((plan) {
          final bool isRecommended = plan['isPopular'] ?? false;
          return _PlanCard(
            plan: plan,
            isSelected: _selectedPlanName == plan['name'].toLowerCase(),
            isCurrent: widget.activePlan['planName']?.toLowerCase() ==
                plan['name'].toLowerCase(),
            isRecommended: isRecommended, // Now passing the recommended status
            onSelect: () =>
                setState(() => _selectedPlanName = plan['name'].toLowerCase()),
          );
        }).toList(),

        const SizedBox(height: 16),

        // --- CRM Lite Promo Banner ---
        if (!(widget.activePlan['hasCRM'] ?? false))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF206C5E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF206C5E).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF206C5E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.contact_phone,
                      color: Color(0xFF206C5E), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("Try CRM Lite",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF206C5E).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("NEW",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF206C5E))),
                          ),
                          const Spacer(),
                          Text(
                            priceText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF206C5E),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Manage leads, track deals & boost sales. Available as an add-on in the next step.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep2() {
    final companyAddon = _addons
        .firstWhere((a) => a['label'].contains("Company"), orElse: () => null);
    final employeeAddon = _addons
        .firstWhere((a) => a['label'].contains("Employee"), orElse: () => null);
    final crmAddon = _addons.firstWhere((a) => a['label'].contains("CRM"),
        orElse: () => null);

    return Column(
      children: [
        if (companyAddon != null)
          _AddonCounterTile(
            label: "Additional Companies",
            value: _extraCompanies,
            price: isTopUp
                ? PricingEngine.calculateProratedPrice(
                    companyAddon['price'], prorationFactor)
                : companyAddon['price'],
            onChanged: (val) => setState(() => _extraCompanies = val),
          ),
        const SizedBox(height: 12),
        if (employeeAddon != null)
          _AddonCounterTile(
            label: "Additional Employees",
            value: _extraEmployees,
            price: isTopUp
                ? PricingEngine.calculateProratedPrice(
                    employeeAddon['price'], prorationFactor)
                : employeeAddon['price'],
            onChanged: (val) => setState(() => _extraEmployees = val),
          ),
        const SizedBox(height: 12),
        if (crmAddon != null)
          _CRMSwitchTile(
            enabled: _crmEnabled,
            price: isTopUp
                ? PricingEngine.calculateProratedPrice(
                    crmAddon['price'], prorationFactor)
                : crmAddon['price'],
            onChanged: (val) => setState(() => _crmEnabled = val),
          ),
        const Divider(height: 40),
        _buildPriceBreakdown(),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    // 1. Find the selected plan object
    final selectedPlan = _plans.firstWhere(
      (p) => p['name'].toLowerCase() == _selectedPlanName,
      orElse: () => {'price': 0},
    );

    // 2. Base Price: Only charge if it's NOT a top-up (new plan or renewal)
    // If it's a top-up, we assume base is already paid.
    // If the plan is EXPIRED, isTopUp should be false so they pay the base price again.
    int basePrice = isTopUp ? 0 : (selectedPlan['price'] ?? 0);

    // 3. Add-on Prices
    final companyAddon = _addons.firstWhere(
        (a) => a['label'].contains("Company"),
        orElse: () => {'price': 0});
    final employeeAddon = _addons.firstWhere(
        (a) => a['label'].contains("Employee"),
        orElse: () => {'price': 0});
    final crmAddon = _addons.firstWhere((a) => a['label'].contains("CRM"),
        orElse: () => {'price': 0});

    int unitComp = isTopUp
        ? PricingEngine.calculateProratedPrice(
            companyAddon['price'], prorationFactor)
        : (companyAddon['price'] ?? 0);
    int unitEmp = isTopUp
        ? PricingEngine.calculateProratedPrice(
            employeeAddon['price'], prorationFactor)
        : (employeeAddon['price'] ?? 0);
    int unitCrm = isTopUp
        ? PricingEngine.calculateProratedPrice(
            crmAddon['price'], prorationFactor)
        : (crmAddon['price'] ?? 0);

    // 4. Calculate Final Total
    int total =
        basePrice + (_extraCompanies * unitComp) + (_extraEmployees * unitEmp);
    if (_crmEnabled) total += unitCrm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          if (basePrice > 0)
            _priceRow("${selectedPlan['name']} Base", basePrice),
          if (_extraCompanies > 0)
            _priceRow("Add-on: Companies ($_extraCompanies)",
                _extraCompanies * unitComp),
          if (_extraEmployees > 0)
            _priceRow("Add-on: Employees ($_extraEmployees)",
                _extraEmployees * unitEmp),
          if (_crmEnabled) _priceRow("Add-on: CRM Lite", unitCrm),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Total Amount",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("₹${(total as num).toLocaleString('en-IN')}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF206C5E))),
          ]),
          if (isTopUp)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("*Prorated for remaining days",
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[800],
                      fontStyle: FontStyle.italic)),
            )
        ],
      ),
    );
  }

  Widget _priceRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text("₹${(amount as num).toLocaleString('en-IN')}",
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    // Find the currently selected plan object
    final selectedPlan = _plans.firstWhere(
      (p) => p['name'].toLowerCase() == _selectedPlanName,
      orElse: () => null,
    );

    // If Step 1 and the selected plan price is 0 (Free), hide the button
    if (_currentStep == 1 &&
        selectedPlan != null &&
        (selectedPlan['price'] ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF206C5E),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        onPressed: () {
          if (_currentStep == 1) {
            setState(() => _currentStep = 2);
          } else {
            // Add your Handle Payment logic here
          }
        },
        child: Text(_currentStep == 1
            ? "Customize Add-ons"
            : (isTopUp ? "Confirm & Pay" : "Proceed to Payment")),
      ),
    );
  }
}
