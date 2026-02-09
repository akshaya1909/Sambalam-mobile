import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/company_categories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/company_api_service.dart';

class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({Key? key}) : super(key: key);

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _udyamController = TextEditingController();

  String? _selectedBusinessType;

  // Image handling variables
  String? _serverLogoUrl; // The URL coming from DB
  XFile? _pickedImageFile; // The file picked from Gallery
  final ImagePicker _picker = ImagePicker();

  String? _companyId;
  bool _loading = true;

  final CompanyApiService _companyApi = CompanyApiService();

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');
      if (companyId == null) {
        setState(() => _loading = false);
        return;
      }
      _companyId = companyId;

      final company = await _companyApi.getCompanyDetailsById(companyId);

      _nameController.text = (company['name'] ?? '') as String;
      _addressController.text = (company['address'] ?? '') as String;
      _gstController.text = (company['gstNumber'] ?? '') as String;
      _udyamController.text = (company['udyamNumber'] ?? '') as String;
      _serverLogoUrl = company['logo'] as String?;

      final category = company['category'] as String?;
      _selectedBusinessType =
          category != null && category.isNotEmpty ? category : null;

      setState(() {
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // FUNCTION TO PICK IMAGE
  Future<void> _pickImage() async {
    try {
      // If on Mobile, show a selection dialog. If on Web, just open file explorer.
      ImageSource? source;

      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      }

      if (source != null) {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 500, // Limit size for company logo
        );

        if (pickedFile != null) {
          setState(() {
            _pickedImageFile = pickedFile;
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _udyamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF206C5E);
    const Color bg = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Company details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _headerCard(primary),
                    const SizedBox(height: 16),
                    _logoCard(primary),
                    const SizedBox(height: 18),
                    _formCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _bottomButtons(primary),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_center_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit company profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Keep your legal details and billing information up to date.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoCard(Color primary) {
    // Determine which image provider to use
    ImageProvider? imageProvider;
    if (_pickedImageFile != null) {
      if (kIsWeb) {
        // On web, the path is a blob URL string
        imageProvider = NetworkImage(_pickedImageFile!.path);
      } else {
        // On mobile, use FileImage
        imageProvider = FileImage(File(_pickedImageFile!.path));
      }
    } else if (_serverLogoUrl != null && _serverLogoUrl!.isNotEmpty) {
      final String fullUrl = _serverLogoUrl!.startsWith('http')
          ? _serverLogoUrl!
          : '${CompanyApiService.baseUrl}$_serverLogoUrl';
      imageProvider = NetworkImage(fullUrl);
    }
    return Card(
      elevation: 1.2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                    image: imageProvider != null
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageProvider == null
                      ? const Center(
                          child: Text('LOGO',
                              style: TextStyle(color: Color(0xFF9CA3AF))),
                        )
                      : null,
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Company logo',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard() {
    return Card(
      elevation: 1.2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel('Company name'),
              const SizedBox(height: 6),
              _textField(
                controller: _nameController,
                hint: 'Company name',
              ),
              const SizedBox(height: 16),
              _fieldLabel('Business type'),
              const SizedBox(height: 6),
              _businessTypeDropdown(),
              const SizedBox(height: 16),
              _fieldLabel('Company address'),
              const SizedBox(height: 6),
              _textField(
                controller: _addressController,
                hint: 'Company address',
              ),
              const SizedBox(height: 16),
              _fieldLabel('GST number'),
              const SizedBox(height: 6),
              _textField(
                controller: _gstController,
                hint: 'GST number',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Udyam registration number'),
              const SizedBox(height: 6),
              _textField(
                controller: _udyamController,
                hint: 'Udyam registration number',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF206C5E), width: 1.4),
        ),
      ),
    );
  }

  Widget _businessTypeDropdown() {
    final items = ['Select', ...companyCategories];

    String? displayValue = _selectedBusinessType;
    if (displayValue != null && !companyCategories.contains(displayValue)) {
      displayValue = 'Select';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayValue ?? 'Select',
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ['Select', ...companyCategories].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            setState(
                () => _selectedBusinessType = (val == 'Select') ? null : val);
          },
        ),
      ),
    );
  }

  Widget _bottomButtons(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Discard',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                if (_companyId == null) return;
                Uint8List? imageBytes;
                if (_pickedImageFile != null) {
                  imageBytes = await _pickedImageFile!.readAsBytes();
                }

                await _companyApi.updateCompany(
                  companyId: _companyId!,
                  name: _nameController.text.trim(),
                  category: _selectedBusinessType ?? '',
                  address: _addressController.text.trim(),
                  gstNumber: _gstController.text.trim(),
                  udyamNumber: _udyamController.text.trim(),
                  localFilePath: kIsWeb ? null : _pickedImageFile?.path,
                  webImageBytes: imageBytes,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Company details updated')),
                  );
                  _loadCompany();
                }
              },
              child: const Text(
                'Save changes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
