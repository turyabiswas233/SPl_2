import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstColor.primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ConstColor.primaryColor,
        title: const Text('About Dromos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ConstColor.primaryPurple.withAlpha(18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: ConstColor.primaryPurple,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Built for campus travel',
                  style: ConstFonts.bold(
                    size: 22,
                    color: ConstColor.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dromos is designed to make student and campus rides faster, simpler, and more organized. It helps you move around with less waiting, clearer ride details, and better trip planning.',
                  style: ConstFonts.normal(
                    size: 14,
                    color: ConstColor.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Why use Dromos',
            style: ConstFonts.bold(size: 18, color: ConstColor.primaryColor),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.verified_user_outlined,
            title: 'Trusted profile-based travel',
            description:
                'Manage your profile, stay signed in securely, and keep your ride details tied to your account.',
          ),
          _buildInfoCard(
            icon: Icons.access_time_outlined,
            title: 'Save time',
            description:
                'Find nearby rides, create trips quickly, and reduce the effort of arranging travel on your own.',
          ),
          _buildInfoCard(
            icon: Icons.payments_outlined,
            title: 'Keep ride history in one place',
            description:
                'Review your payment history and past ride activity whenever you need a quick record.',
          ),
          const SizedBox(height: 20),
          Text(
            'Available features',
            style: ConstFonts.bold(size: 18, color: ConstColor.primaryColor),
          ),
          const SizedBox(height: 12),
          _buildFeatureTile(Icons.add_circle_outline, 'Create a ride request'),
          _buildFeatureTile(
            Icons.directions_car_outlined,
            'Browse nearby rides',
          ),
          _buildFeatureTile(
            Icons.local_activity_outlined,
            'Track activity updates',
          ),
          _buildFeatureTile(
            Icons.person_outline,
            'Edit and maintain your profile',
          ),
          _buildFeatureTile(
            Icons.notifications_none,
            'Receive app notifications',
          ),
          _buildFeatureTile(
            Icons.receipt_long_outlined,
            'View payment history',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ConstColor.primaryPurple.withAlpha(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ConstColor.primaryPurple.withAlpha(18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ConstColor.primaryPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ConstFonts.semibold(
                    size: 15,
                    color: ConstColor.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: ConstFonts.normal(
                    size: 13,
                    color: ConstColor.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: ConstColor.primaryPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: ConstFonts.light(size: 14, color: ConstColor.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
