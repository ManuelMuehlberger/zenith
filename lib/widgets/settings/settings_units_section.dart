import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class SettingsUnitsSection extends StatelessWidget {
  final UserProfile? userProfile;
  final Function(String) onUnitsChanged;

  const SettingsUnitsSection({
    super.key,
    required this.userProfile,
    required this.onUnitsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'Units',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(CupertinoIcons.gauge, color: Colors.grey[400], size: 24),
                title: const Text('Weight Units', style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoSlidingSegmentedControl<String>(
                    backgroundColor: Colors.grey[800]!,
                    thumbColor: Colors.blue,
                    groupValue: userProfile?.units ?? 'metric',
                    children: const {
                      'metric': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'kg',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      'imperial': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'lbs',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        onUnitsChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
