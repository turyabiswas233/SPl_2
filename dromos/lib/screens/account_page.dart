import 'package:dromos/main.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/info.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.transparent,
        foregroundColor: ConstColor.primaryColor,
        // scrolledUnderElevation: 0,
        // elevation: 0,
        leading: BackButton(
          color: ConstColor.primaryPurple,
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MyApp()),
              (Route<dynamic> route) =>
                  false, // This predicate removes all previous routes
            );
          },
        ),
      ),
      backgroundColor: ConstColor.primaryBg,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileInfoCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    Color accentColor = ConstColor.primaryPurple;
    return Container(
      // 1. Decoration handles Color, Radius, and Shadow
      decoration: BoxDecoration(
        color: ConstColor.primaryPurple,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(100),
            // Shadow color (with transparency)
            spreadRadius: 2,
            // How much the shadow grows
            blurRadius: 10,
            // How soft the shadow edges are
            offset: const Offset(
              0,
              4,
            ), // X and Y offset (changes light direction)
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ConstInfo.userName,
                    style: TextStyle(
                      fontSize: 20,
                      color: ConstColor.primaryBg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    ConstInfo.departmentName,
                    style: TextStyle(
                      fontSize: 12,
                      color: ConstColor.primaryBg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    ConstInfo.hallName,
                    style: TextStyle(
                      fontSize: 12,
                      color: ConstColor.primaryBg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: CircleAvatar(
                radius: 40,
                // Added a slightly darker shade for the circle background for contrast
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.face, size: 50, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    Color accentColor = ConstColor.primaryPurple;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(50),
            // Shadow color (with transparency)
            spreadRadius: 2,
            // How much the shadow grows
            blurRadius: 10,
            // How soft the shadow edges are
            offset: const Offset(
              0,
              4,
            ), // X and Y offset (changes light direction)
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile('Settings', Icons.settings_outlined, () {
            // TODO: Navigate to Settings page
          }),
          _buildListTile('File a Complain', Icons.report_problem_outlined, () {
            // TODO: Navigate to Complain page
          }),
          _buildListTile('About Us', Icons.info_outline, () {
            // TODO: Navigate to About Us page
          }),
          _buildListTile('Contact Us', Icons.contact_support_outlined, () {
            // TODO: Navigate to Contact Us page
          }),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ConstColor.primaryPurple, size: 20),
      title: Text(title, style: TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
      style: ListTileStyle.list,
      onTap: onTap,
    );
  }
}
