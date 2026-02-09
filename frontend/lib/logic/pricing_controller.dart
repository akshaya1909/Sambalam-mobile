class PricingController {
  static const double baseProPrice = 5000;
  static const double additionalCompanyPrice = 3000;
  static const double additionalEmployeePrice = 100;
  static const double crmLitePrice = 2000;

  String plan = 'free'; // 'free' or 'pro'
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