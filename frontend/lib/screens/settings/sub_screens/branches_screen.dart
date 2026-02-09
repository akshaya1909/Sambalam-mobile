import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/branch_api_service.dart';
import '../../../models/branch_model.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({Key? key}) : super(key: key);

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final BranchApiService _branchApi = BranchApiService();

  List<Branch> _branches = [];
  bool _isLoading = true;
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyId');
    if (_companyId != null) {
      _fetchBranches();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBranches() async {
    if (_companyId == null) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await _branchApi.getCompanyBranches(_companyId!);
      if (mounted) {
        setState(() {
          _branches = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load branches');
      }
    }
  }

  // --- NEW: Delete Confirmation Dialog ---
  Future<void> _confirmDelete(String branchId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Branch'),
        content: const Text(
          'Are you sure you want to delete this branch? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deleteBranch(branchId);
    }
  }

  Future<void> _deleteBranch(String branchId) async {
    try {
      await _branchApi.deleteBranch(branchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch deleted successfully')),
        );
      }
      _fetchBranches(); // Refresh list
    } catch (e) {
      _showError('Failed to delete branch');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _openBranchForm({Branch? branch}) {
    if (_companyId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BranchForm(
        companyId: _companyId!,
        branch: branch,
        onSave: () {
          Navigator.pop(ctx);
          _fetchBranches();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF3F4F6);
    const Color primary = Color(0xFF206C5E);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Branches',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBranchForm(),
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Branch'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    return _buildBranchCard(branch);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.map_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No branches added yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(Branch branch) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          branch.name.isNotEmpty
                              ? branch.name[0].toUpperCase()
                              : 'B',
                          style: const TextStyle(
                              color: Color(0xFF206C5E),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Radius: ${branch.radius.toStringAsFixed(0)}m',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openBranchForm(branch: branch);
                    } else if (value == 'delete') {
                      // Trigger Confirmation Dialog
                      _confirmDelete(branch.id);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    branch.address,
                    style:
                        const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- FORM WIDGET (Using New Service) ---

class _BranchForm extends StatefulWidget {
  final String companyId;
  final Branch? branch;
  final VoidCallback onSave;

  const _BranchForm(
      {Key? key, required this.companyId, this.branch, required this.onSave})
      : super(key: key);

  @override
  State<_BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends State<_BranchForm> {
  final _formKey = GlobalKey<FormState>();
  final BranchApiService _branchApi = BranchApiService();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _radiusController;
  late LatLng _selectedLocation;
  bool _isSaving = false;

  GoogleMapController? _mapController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _radiusFocus = FocusNode();

  // 1. IMPORTANT: Replace this with your Google Maps API Key
  final String googleApiKey = "AIzaSyA1CJSLQZwULl7JZ1SJXVQEkGPjxOLG2SU";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _addressController =
        TextEditingController(text: widget.branch?.address ?? '');
    _radiusController =
        TextEditingController(text: widget.branch?.radius.toString() ?? '100');

    if (widget.branch != null) {
      _selectedLocation =
          LatLng(widget.branch!.latitude, widget.branch!.longitude);
    } else {
      // Default to Chennai or any default center
      _selectedLocation = const LatLng(13.0827, 80.2707);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    _mapController?.dispose();
    _nameFocus.dispose();
    _searchFocus.dispose();
    _radiusFocus.dispose();
    super.dispose();
  }

  // Moves the map camera when an address is selected from search
  void _moveCamera(LatLng latLng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.branch == null) {
        await _branchApi.createBranch(
          companyId: widget.companyId,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          radius: double.tryParse(_radiusController.text) ?? 100,
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
        );
      } else {
        await _branchApi.updateBranch(
          branchId: widget.branch!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          radius: double.tryParse(_radiusController.text) ?? 100,
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
        );
      }
      widget.onSave();
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving branch: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF206C5E);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.branch == null ? 'Add Branch' : 'Edit Branch',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context))
            ],
          ),
          const Divider(),

          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Branch Name'),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: _inputDecoration('e.g. Downtown Office'),
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. REAL-TIME SEARCH WIDGET (Mimics branches.tsx)
                    _buildLabel('Search & Select Address'),
                    GooglePlaceAutoCompleteTextField(
                      textEditingController: _addressController,
                      focusNode: _searchFocus,
                      googleAPIKey:
                          googleApiKey, // Ensure this is just the raw key string
                      inputDecoration:
                          _inputDecoration('Start typing address...'),
                      debounceTime: 800,
                      countries: ["in"],
                      // This is the correct callback for the package to fetch Lat/Lng
                      getPlaceDetailWithLatLng: (Prediction prediction) {
                        if (prediction.lat != null && prediction.lng != null) {
                          double lat = double.parse(prediction.lat!);
                          double lng = double.parse(prediction.lng!);

                          setState(() {
                            _addressController.text =
                                prediction.description ?? "";
                            _selectedLocation = LatLng(lat, lng);
                          });

                          // Move map to the searched location
                          _moveCamera(_selectedLocation);
                        }
                      },
                      itemClick: (Prediction prediction) {
                        _addressController.text = prediction.description ?? "";
                        _addressController.selection =
                            TextSelection.fromPosition(TextPosition(
                                offset: prediction.description?.length ?? 0));
                      },
                    ),
                    const SizedBox(height: 10),

                    // Selected Address Display
                    _buildLabel('Confirmed Address'),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      readOnly: true,
                      style: const TextStyle(color: Colors.black87),
                      decoration:
                          _inputDecoration('Address will appear here').copyWith(
                        fillColor: Colors.grey
                            .shade100, // Light grey background to show it's read-only
                        prefixIcon: const Icon(Icons.check_circle,
                            color: primary, size: 20),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Geofence Radius (meters)'),
                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('100'),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Adjust Precise Location'),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _selectedLocation,
                                zoom: 15,
                              ),
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                              onCameraMove: (position) {
                                _selectedLocation = position.target;
                              },
                              zoomControlsEnabled: false,
                            ),
                            // The Fixed Center Pin
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 35), // ✅ Fixed Syntax
                                child: const Icon(
                                  Icons.location_on,
                                  size: 40,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Search for address or drag the map to position the red pin exactly.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      widget.branch == null ? 'Create Branch' : 'Update Branch',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    );
  }
}
