import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/models/marketplace_model.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/services/image_uploader.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/widgets/floating_messages_button.dart';
import 'package:stateful_widget/chat_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  int _navIndex = 1;
  String _selectedCategory = 'All';

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

  static const List<String> _categories = ['All', 'Books', 'Electronics', 'Clothing', 'Others'];

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _condition.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  /* ---------- NAVIGATION ---------- */
  //void _handleNavTap(int index) {
    //if (index == 1) return;
    //final route = {0: '/home', 2: '/wall', 4: '/profile'}[index];
    //if (route != null) {
      //Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    //}
  //}

  /* ---------- IMAGE ---------- */
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

  /* ---------- SUBMIT ---------- */
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
    final user = FirebaseAuth.instance.currentUser!;
    final item = MarketplaceItem(
      authorId: user.uid,
      authorName: user.displayName ?? 'User',
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
      Navigator.pop(context);
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

  /* ---------- CHAT ---------- */
  void _openChatWithSeller(MarketplaceItem item) async {
    try {
      final convId = await _db.getOrCreateDirectConversation(item.authorId);
      if (!mounted) return;
      final otherUserDoc = await _db.getUser(item.authorId);
      final otherName = (otherUserDoc.data() as Map<String, dynamic>)?['displayName'] ?? item.authorName;

      final conversation = {
        'id': convId,
        'name': otherName,
        'subtitle': 'Direct message',
        'emoji': '💬',
        'avatarColor': const Color(0xFFFFE9E2),
        'accent': const Color(0xFFE85D5D),
        'group': false,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(conversation: conversation),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /* ---------- MODAL ---------- */
  void _showPostItemModal() {
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
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
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

  /* ---------- HEADER / SEARCH / TABS (same as before) ---------- */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingMessagesButton(
        badgeCount: 4,
        onPressed: () => Navigator.pushNamed(context, '/messages'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: _handleNavTap,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildCategoryTabs(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showPostItemModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8D0B15),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text(
                            'Post Item',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db.getMarketplaceItemsStream(),
                      builder: (context, snap) {
                        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final items = snap.data!.docs
                            .map((d) => MarketplaceItem.fromFirestore(d))
                            .toList();
                        if (items.isEmpty) {
                          return const Center(child: Text('No items yet'));
                        }
                        final filtered = _selectedCategory == 'All'
                            ? items
                            : items.where((i) => i.category == _selectedCategory).toList();
                        return Column(
                          children: filtered.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                children: [
                                  _buildMarketplaceItemCard(item, theme),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openChatWithSeller(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8D0B15),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                      label: const Text(
                                        'Message Seller',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF921126), Color(0xFFD4372A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Marketplace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Buy & sell with campus community',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search items...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.tune, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories
              .map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategory == category
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _selectedCategory == category
                                ? Colors.black
                                : const Color(0xFF8D0B15),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMarketplaceItemCard(MarketplaceItem item, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 241, 237),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: item.photoUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: item.photoUrls,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                ),
              ),
              if (item.urgent)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE84535),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4A1C1C),
                        ),
                      ),
                    ),
                    Text(
                      '₱${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8D0B15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip(item.category, Colors.grey[200]!, Colors.grey[700]!),
                    const SizedBox(width: 8),
                    _chip(item.condition, const Color(0xFFFFA500), Colors.white),
                    if (item.urgent) ...[
                      const SizedBox(width: 8),
                      _chip('Urgent', const Color(0xFFE84535), Colors.white),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item.authorName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );

  void _handleNavTap(int index) {
    if (index == _navIndex) return;
    setState(() => _navIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/wall');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/alerts');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
