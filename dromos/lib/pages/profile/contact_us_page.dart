import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstColor.primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ConstColor.primaryColor,
        title: const Text('Contact Us'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: ConstFonts.bold(
                    size: 22,
                    color: ConstColor.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Contact us if you face login issues, profile update problems, ride booking questions, payment concerns, or if you want to report a bug or share feedback about the app.',
                  style: ConstFonts.normal(
                    size: 14,
                    color: ConstColor.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildContactCard(
            label: 'Developer 1',
            phone: '+880 1571-316093',
            email: 'bsse1501@iit.du.ac.bd',
          ),
          _buildContactCard(
            label: 'Developer 2',
            phone: '+880 1540-153659',
            email: 'bsse1507@iit.du.ac.bd',
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String label,
    required String phone,
    required String email,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ConstColor.primaryPurple.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ConstFonts.semibold(
              size: 16,
              color: ConstColor.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.phone_outlined, phone),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.email_outlined, email),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ConstColor.primaryPurple, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: ConstFonts.normal(size: 14, color: ConstColor.primaryColor),
          ),
        ),
      ],
    );
  }
}
