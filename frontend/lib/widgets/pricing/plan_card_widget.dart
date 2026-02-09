// Plan Card Widget
class _PlanCard extends StatelessWidget {
  final String name;
  final double price;
  final int companies, employees;
  final bool isSelected, isRecommended;
  final VoidCallback onTap;

  const _PlanCard({required this.name, required this.price, required this.companies, 
    required this.employees, required this.isSelected, required this.onTap, this.isRecommended = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F5F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF206C5E) : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF206C5E)),
              ],
            ),
            const SizedBox(height: 8),
            Text(price == 0 ? "Free" : "₹${price.toInt().toString()}/yr", 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _FeatureRow(icon: Icons.business, text: "$companies Company"),
            const SizedBox(height: 4),
            _FeatureRow(icon: Icons.people, text: "$employees Employees"),
          ],
        ),
      ),
    );
  }
}

// Add-On Counter Widget
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
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("₹${price.toInt()}/yr each", style: const TextStyle(fontSize: 12, color: Color(0xFF206C5E), fontWeight: FontWeight.bold)),
            ]),
          ),
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: value > 0 ? () => onChanged(value - 1) : null),
          Text("$value", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

// CRM Toggle Widget
class _CRMLiteToggle extends StatelessWidget {
  final bool enabled;
  final Function(bool) onChanged;
  const _CRMLiteToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.contact_mail, color: Color(0xFF206C5E)),
          const SizedBox(width: 12),
          const Expanded(child: Text("CRM Lite Add-on\nLead management & reports", style: TextStyle(fontSize: 13))),
          Switch(value: enabled, activeColor: const Color(0xFF206C5E), onChanged: onChanged),
        ],
      ),
    );
  }
}

// Price Breakdown Table
class _PriceBreakdown extends StatelessWidget {
  final PricingController ctrl;
  const _PriceBreakdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _summaryRow("Pro Plan Base", 5000),
          if (ctrl.additionalCompanies > 0) 
            _summaryRow("Addl. Companies (${ctrl.additionalCompanies})", ctrl.additionalCompanies * 3000.0),
          if (ctrl.additionalEmployees > 0)
            _summaryRow("Addl. Employees (${ctrl.additionalEmployees})", ctrl.additionalEmployees * 100.0),
          if (ctrl.crmLite) _summaryRow("CRM Lite", 2000),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Total (Annual)", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("₹${ctrl.total.toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF206C5E))),
          ])
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(fontSize: 13)), Text("₹${price.toInt()}")],
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
    return Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 13))]);
  }
}

class _CRMPromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
      child: const Row(children: [
        Icon(Icons.sparkles, color: Colors.blue, size: 20),
        SizedBox(width: 10),
        Expanded(child: Text("Try CRM Lite to manage leads and boost sales. Available in next step.", style: TextStyle(fontSize: 12))),
      ]),
    );
  }
}