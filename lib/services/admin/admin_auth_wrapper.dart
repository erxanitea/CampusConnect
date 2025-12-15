import 'package:flutter/material.dart';
import 'package:stateful_widget/services/admin/admin_service.dart';

class AdminAuthWrapper extends StatelessWidget {
  final Widget adminChild;
  final Widget userChild;
  final Widget loadingChild;
  
  const AdminAuthWrapper({
    super.key,
    required this.adminChild,
    required this.userChild,
    this.loadingChild = const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminService().isCurrentUserAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingChild;
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        
        final isAdmin = snapshot.data ?? false;
        
        return isAdmin ? adminChild : userChild;
      },
    );
  }
}
