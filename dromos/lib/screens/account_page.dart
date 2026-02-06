import 'package:dromos/pages/home/home_page.dart';
import 'package:dromos/screens/editprofile_page.dart';
import 'package:dromos/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  static const Color accentColor = ConstColor.primaryPurple;
  static const Color fColor = ConstColor.primaryColor;
  static const Color bColor = ConstColor.primaryBg;
  static const Color maleColor = Colors.lightBlue;
  static const Color femaleColor = Colors.purpleAccent;

  @override
  void initState() {
    super.initState();
    // Refresh profile on page load if data is stale
    if (_userService.currentUser.isEmpty && _userService.isLoggedIn) {
      _refreshProfile();
    }
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    await _userService.fetchProfile();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.transparent,
        foregroundColor: ConstColor.primaryColor,
      ),
      backgroundColor: ConstColor.primaryBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProfileInfoCard(),
                Row(
                  mainAxisSize: MainAxisSize.min, // Prevent Row from expanding
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 12,
                        ), // Adjust padding
                        minimumSize: Size.zero, // Remove default min size
                        tapTargetSize: MaterialTapTargetSize
                            .shrinkWrap, // Remove extra space
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 14,
                          color: bColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
    );
  }

  Widget _buildProfileInfoCard() {
    final user = _userService.currentUser;
    Color genderColor = user.gender.toLowerCase() == 'male'
        ? maleColor
        : femaleColor;

    return Container(
      // 1. Decoration handles Color, Radius, and Shadow
      decoration: BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              // Added a slightly darker shade for the circle background for contrast
              backgroundColor: genderColor.withAlpha(50),
              child: Icon(
                user.gender == 'male'? Icons.person_rounded : Icons.person_2_rounded,
                size: 50,
                color: genderColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              user.fullName.isNotEmpty ? user.fullName : 'User',
              style: TextStyle(
                fontSize: 20,
                color: fColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 16),

            Text(
              user.email.isNotEmpty ? user.email : 'User@example.com',
              style: TextStyle(
                fontSize: 14,
                color: fColor,
                fontWeight: FontWeight.w400,
              ),
            ),

            Text(
              user.deptName.isNotEmpty ? user.deptName : '—',
              style: TextStyle(
                fontSize: 14,
                color: fColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          _buildListTile(
            'Logout',
            Icons.logout,
            () {
              _handleLogout();
            },
            color: Colors.red,
            dense: false,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    bool dense = true,
  }) {
    final tileColor = color ?? ConstColor.primaryPurple;
    return ListTile(
      leading: Icon(icon, color: tileColor, size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, color: color)),
      trailing: dense ? const Icon(Icons.arrow_forward_ios, size: 12) : null,
      style: ListTileStyle.list,
      onTap: onTap,
    );
  }
}
