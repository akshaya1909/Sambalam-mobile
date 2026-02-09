import 'package:flutter/material.dart';

// --- PRICING LOGIC ---
class PricingController {
  static const double baseProPrice = 5000;
  static const double additionalCompanyPrice = 3000;
  static const double additionalEmployeePrice = 100;
  static const double crmLitePrice = 2000;

  String plan = 'pro'; // Default to Pro for the upgrade flow
  int additionalCompanies = 0;
  int additionalEmployees = 0;
  bool crmLite = false;

  double get total {
    if (plan == 'free') return 0;
    double sum = baseProPrice;
    sum += additionalCompanies * additionalCompanyPrice;
    sum += additionalEmployees * additionalEmployeePrice;
    if (crmLite) sum += crmLitePrice;
    return sum;
  }

  Map<String, int> get limits {
    if (plan == 'free') return {'companies': 1, 'employees': 5};
    int cos = 1 + additionalCompanies;
    return {
      'companies': cos,
      'employees': (cos * 20) + additionalEmployees,
    };
  }
}

// --- MAIN SCREEN ---
class SubscriptionBillingScreen extends StatefulWidget {
  const SubscriptionBillingScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionBillingScreen> createState() => _SubscriptionBillingScreenState();
}

class _SubscriptionBillingScreenState extends State<SubscriptionBillingScreen> {
  int step = 1;
  final PricingController _ctrl = PricingController();

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF206C5E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(step == 1 ? Icons.close : Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (step == 2) {
              setState(() => step = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          step == 1 ? 'Choose Your Plan' : 'Customize Your Plan',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: step == 1 ? _buildStep1() : _buildStep2(),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select the plan that best fits your business needs.",
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const SizedBox(height: 20),
        _PlanCard(
          name: "Free Plan",
          price: 0,
          companies: 1,
          employees: 5,
          isSelected: _ctrl.plan == 'free',
          onTap: () => setState(() => _ctrl.plan = 'free'),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          name: "Pro Plan",
          price: 5000,
          companies: 1,
          employees: 20,
          isSelected: _ctrl.plan == 'pro',
          isRecommended: true,
          onTap: () => setState(() => _ctrl.plan = 'pro'),
        ),
        const SizedBox(height: 20),
        _CRMPromoBanner(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add more companies or employees to your plan.",
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const SizedBox(height: 20),
        _AddOnCounter(
          label: "Additional Companies",
          sub: "Each company includes 20 employees",
          price: 3000,
          value: _ctrl.additionalCompanies,
          onChanged: (v) => setState(() => _ctrl.additionalCompanies = v),
        ),
        const SizedBox(height: 12),
        _AddOnCounter(
          label: "Additional Employees",
          sub: "Add more employees across all companies",
          price: 100,
          value: _ctrl.additionalEmployees,
          onChanged: (v) => setState(() => _ctrl.additionalEmployees = v),
        ),
        const SizedBox(height: 16),
        _CRMLiteToggle(
          enabled: _ctrl.crmLite,
          onChanged: (v) => setState(() => _ctrl.crmLite = v),
        ),
        const SizedBox(height: 16),
        // Limits Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F5F1).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF206C5E).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _limitItem("Companies", _ctrl.limits['companies']!),
              _limitItem("Employees", _ctrl.limits['employees']!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PriceBreakdown(ctrl: _ctrl),
      ],
    );
  }

  Widget _limitItem(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text("$value", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF206C5E))),
      ],
    );
  }

  Widget _buildBottomBar(Color primaryColor) {
    bool isPro = _ctrl.plan == 'pro';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () {
          if (step == 1 && isPro) {
            setState(() => step = 2);
          } else {
            // Handle Payment/Downgrade
            print("Total: ${_ctrl.total}");
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(step == 1 && isPro ? Icons.tune : Icons.credit_card, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              step == 1 && isPro ? "Customize Add-ons" : "Proceed to Payment",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SUPPORTING WIDGETS ---

class _PlanCard extends StatelessWidget {
  final String name;
  final double price;
  final int companies, employees;
  final bool isSelected, isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.companies,
    required this.employees,
    required this.isSelected,
    required this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF206C5E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F5F1).withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20)),
                    child: const Text("Recommended", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  price == 0 ? "Free" : "₹${price.toInt().toString()}/yr",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 32),
                _FeatureRow(icon: Icons.business_outlined, text: "$companies Company"),
                const SizedBox(height: 8),
                _FeatureRow(icon: Icons.groups_outlined, text: "$employees Employees"),
              ],
            ),
            if (isSelected)
              const Positioned(top: 0, right: 0, child: Icon(Icons.check_circle, color: primary)),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF206C5E)),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
    ]);
  }
}

class _AddOnCounter extends StatelessWidget {
  final String label, sub;
  final double price;
  final int value;
  final Function(int) onChanged;

  const _AddOnCounter({required this.label, required this.sub, required this.price, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text("₹${price.toInt()}/yr each", style: const TextStyle(fontSize: 13, color: Color(0xFF206C5E), fontWeight: FontWeight.bold)),
            ]),
          ),
          Row(
            children: [
              _counterBtn(Icons.remove, () => onChanged(value - 1), value > 0),
              SizedBox(width: 40, child: Center(child: Text("$value", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              _counterBtn(Icons.add, () => onChanged(value + 1), true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, bool active) {
    return InkWell(
      onTap: active ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: active ? const Color(0xFF206C5E) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: active ? const Color(0xFF206C5E) : Colors.grey.shade300),
      ),
    );
  }
}

class _CRMLiteToggle extends StatelessWidget {
  final bool enabled;
  final Function(bool) onChanged;
  const _CRMLiteToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFE6F5F1).withOpacity(0.3), Colors.white]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF206C5E).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE6F5F1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.contact_phone_outlined, color: Color(0xFF206C5E)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CRM Lite", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Lead management & reports", style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Switch(value: enabled, activeColor: const Color(0xFF206C5E), onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final PricingController ctrl;
  const _PriceBreakdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _summaryRow("Pro Plan (Base)", PricingController.baseProPrice),
          if (ctrl.additionalCompanies > 0)
            _summaryRow("Additional Companies (x${ctrl.additionalCompanies})", ctrl.additionalCompanies * PricingController.additionalCompanyPrice),
          if (ctrl.additionalEmployees > 0)
            _summaryRow("Additional Employees (x${ctrl.additionalEmployees})", ctrl.additionalEmployees * PricingController.additionalEmployeePrice),
          if (ctrl.crmLite)
            _summaryRow("CRM Lite Add-on", PricingController.crmLitePrice),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total (Annual)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹${ctrl.total.toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF206C5E))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          Text("₹${price.toInt()}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CRMPromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Manage leads and track deals with CRM Lite. Available as an add-on in the next step.",
              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }
}