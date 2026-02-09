import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department_model.dart';

class DepartmentApiService {
  // Update with your actual IP
  static const String baseUrl = 'http://10.80.210.30:5000';

  // --- FETCH DEPARTMENTS ---
  Future<List<Department>> getCompanyDepartments(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/department/company/$companyId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Department.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load departments');
    }
  }

  // --- FETCH ALL EMPLOYEES (Needed for mapping & selection) ---
  // Assuming you have an employee route like /api/employee/company/:id
  Future<List<Employee>> getCompanyEmployees(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/employees/company/$companyId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Employee.fromJson(e)).toList();
    } else {
      // Return empty if endpoint fails or doesn't exist yet to prevent crash
      print('Warning: Could not fetch employees: ${res.statusCode}');
      return [];
    }
  }

  // --- CREATE DEPARTMENT ---
  Future<void> createDepartment(String companyId, String name) async {
    final uri = Uri.parse('$baseUrl/api/department/$companyId');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create department');
    }
  }

  // --- DELETE DEPARTMENT ---
  Future<void> deleteDepartment(String departmentId) async {
    final uri = Uri.parse('$baseUrl/api/department/$departmentId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete department');
    }
  }

  // --- ADD STAFF ---
  Future<void> addStaff(String departmentId, String employeeId) async {
    final uri = Uri.parse('$baseUrl/api/department/$departmentId/staff');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'employeeId': employeeId}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to add staff');
    }
  }

  // --- REMOVE STAFF ---
  Future<void> removeStaff(String departmentId, String employeeId) async {
    final uri =
        Uri.parse('$baseUrl/api/department/$departmentId/staff/$employeeId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to remove staff');
    }
  }
}
