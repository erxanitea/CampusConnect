import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/models/marketplace_model.dart';
import 'package:stateful_widget/models/organization_model.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/services/image_uploader.dart';

class OrganizationMarketplaceTab extends StatefulWidget {
  final Organization organization;
  
  const OrganizationMarketplaceTab({
    super.key,
    required this.organization,
  });

  @override
  State<OrganizationMarketplaceTab> createState() => _OrganizationMarketplaceTabState();
}

class _OrganizationMarketplaceTabState extends State<OrganizationMarketplaceTab> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _condition = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String _category = 'Others';
  String? _photoUrls;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isUploadingImage = false;
  bool _isLoading = false;
  bool _imageSelected = false;
  
  // For displaying organization's listings
  List<MarketplaceItem> _organizationItems = [];
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizationItems();
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _condition.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizationItems() async {
    try {
      final items = await _db.getMarketplaceItemsByAuthor(widget.organization.id);
      setState(() {
        _organizationItems = items;
        _loadingItems = false;
      });
    } catch (e) {
      print('Error loading organization items: $e');
      setState(() {
        _loadingItems = false;
      });
    }
  }

  /* ---------- IMAGE UPLOAD ---------- */
  Future<void> _pickImage([StateSetter? modalSetState]) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      _photoUrls = null;
      _isUploadingImage = true;
      _imageSelected = true;
    });

    if (modalSetState != null) {
      modalSetState(() {});
    }

    final url = await ImageUploader.upload(picked);

    setState(() {
      _photoUrls = url;
      _isUploadingImage = false;
    });

    if (modalSetState != null) {
      modalSetState(() {});
    }

    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed, try again')),
      );
    }
  }

  /* ---------- SUBMIT ITEM ---------- */
  Future<void> _submitItem() async {
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for image to finish uploading')),
      );
      return;
    }

    if (!_imageSelected || _photoUrls == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select and wait for photo to upload')),
      );
      return;
    }

    // Validation
    if (_title.text.trim().isEmpty ||
        _price.text.trim().isEmpty ||
        _condition.text.trim().isEmpty ||
        _location.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _photoUrls == null) {

      String errorMsg = 'Please fill: ';
      if (_title.text.trim().isEmpty) errorMsg += 'Title, ';
      if (_price.text.trim().isEmpty) errorMsg += 'Price, ';
      if (_condition.text.trim().isEmpty) errorMsg += 'Condition, ';
      if (_location.text.trim().isEmpty) errorMsg += 'Location, ';
      if (_description.text.trim().isEmpty) errorMsg += 'Description, ';
      if (_photoUrls == null) errorMsg += 'Photo';
      
      if (errorMsg.endsWith(', ')) {
        errorMsg = errorMsg.substring(0, errorMsg.length - 2);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Create marketplace item with organization as author
    final item = MarketplaceItem(
      authorId: widget.organization.id, // Organization ID as author
      authorName: widget.organization.name, // Organization name as author
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      condition: _condition.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      location: _location.text.trim(),
      photoUrls: _photoUrls!,
      urgent: false,
      createdAt: DateTime.now(),
    );
    
    try {
      await _db.createMarketplaceItem(item);
      
      // Refresh the organization's listings
      await _loadOrganizationItems();
      
      // Close modal if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item posted successfully!')),
      );

      _clearModalState();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearModalState() {
    _title.clear();
    _price.clear();
    _condition.clear();
    _location.clear();
    _description.clear();
    _category = 'Others';
    _photoUrls = null;
    _imageBytes = null;
    _isUploadingImage = false;
    _isLoading = false;
    _imageSelected = false;
  }

  /* ---------- MODAL FOR POSTING ---------- */
  void _showPostItemModal() {
    // Reset state
    _title.clear();
    _price.clear();
    _condition.clear();
    _location.clear();
    _description.clear();
    _category = 'Others';
    _photoUrls = null;
    _imageFile = null;
    _imageBytes = null;
    _isUploadingImage = false;
    _isLoading = false;
    _imageSelected = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setStateSB) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Post Item for Sale',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.close), 
                      onPressed: () => Navigator.pop(context)
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Posting as ${widget.organization.name}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Title', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(controller: _title, decoration: _inputDec('Enter item title')),
                const SizedBox(height: 16),
                const Text('Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isUploadingImage ? null : () => _pickImage(setStateSB),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: _isUploadingImage
                        ? Center(child: CircularProgressIndicator())
                        : _photoUrls != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _photoUrls!, 
                              fit: BoxFit.cover
                            ),
                          )
                        : _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.grey[400], size: 40),
                              const SizedBox(height: 8),
                              Text('Tap to add photo', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Price', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: _inputDec('Enter price').copyWith(prefixText: '₱ '),
                ),
                const SizedBox(height: 16),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: ['Books', 'Electronics', 'Clothing', 'Food', 'Others']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setStateSB(() => _category = v!),
                  decoration: _inputDec(null),
                ),
                const SizedBox(height: 16),
                const Text('Condition', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(controller: _condition, decoration: _inputDec('Like New, Good, Excellent')),
                const SizedBox(height: 16),
                const Text('Location', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(controller: _location, decoration: _inputDec('e.g. Lobby in DPT building')),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  maxLines: 4,
                  decoration: _inputDec('Describe your item...'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isUploadingImage) ? null : _submitItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D0B15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: (_isLoading || _isUploadingImage)
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('Post Item', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  Widget _buildMarketplaceItemCard(MarketplaceItem item, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E4DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 241, 237),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: item.photoUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: item.photoUrls,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey[400]),
                      ),
              ),
              if (item.urgent)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE84535),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF4A1C1C),
                        ),
                      ),
                    ),
                    Text(
                      '₱${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF8D0B15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.condition,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.length > 100
                      ? '${item.description.substring(0, 100)}...'
                      : item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item.location,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Posted by: ${item.authorName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sell Item Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1E4DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Color(0xFF8D0B15)),
                    const SizedBox(width: 8),
                    const Text(
                      'Sell Item',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF4A1C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showPostItemModal,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Post New Item',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D0B15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Organization's Listings Section
          const Text(
            'Your Listings',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF4A1C1C),
            ),
          ),
          const SizedBox(height: 12),
          
          if (_loadingItems)
            const Center(child: CircularProgressIndicator())
          else if (_organizationItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'No items listed yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Post New Item" above to list your first item',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: _organizationItems.map((item) => _buildMarketplaceItemCard(item, Theme.of(context))).toList(),
            ),
        ],
      ),
    );
  }
}
