import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = topPadding + kToolbarHeight;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMainContent(headerHeight),
          ),
          // Glass header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  height: headerHeight,
                  color: Colors.black54,
                  child: SafeArea(
                    bottom: false,
                    child: _buildHeaderContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Back button
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
              ),
            ),
            
            // Title
            const Expanded(
              child: Text(
                'Development Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double headerHeight) {
    return CustomScrollView(
      slivers: [
        // Space for header
        SliverToBoxAdapter(
          child: SizedBox(height: headerHeight),
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(CupertinoIcons.rocket_fill, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Roadmap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track the evolution of your workout companion',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildTimelineItem(
                  version: '1.0.0',
                  title: 'Foundation',
                  subtitle: 'Core workout tracking & basic features',
                  status: TimelineStatus.completed,
                  features: [
                    'Workout creation and tracking',
                    'Exercise database integration',
                    'Basic statistics and insights',
                    'Profile management',
                    'Data export/import',
                  ],
                  icon: CupertinoIcons.checkmark_seal_fill,
                  color: Colors.green,
                ),

                _buildTimelineItem(
                  version: '0.2.0',
                  title: 'Enhanced Experience',
                  subtitle: 'Exercise renders & smooth animations',
                  status: TimelineStatus.inProgress,
                  features: [
                    'Exercise demonstration videos',
                    'Smooth page transitions',
                    'Enhanced workout animations',
                    'Improved exercise selection UI',
                    'Better visual feedback',
                  ],
                  icon: CupertinoIcons.play_circle_fill,
                  color: Colors.blue,
                ),

                _buildTimelineItem(
                  version: '0.3.0',
                  title: 'Insights & Widgets',
                  subtitle: 'Advanced analytics & home screen widgets',
                  status: TimelineStatus.planned,
                  features: [
                    'Home screen widgets',
                    'Advanced workout analytics',
                    'Progress tracking charts',
                    'Workout streak counters',
                    'Performance predictions',
                  ],
                  icon: CupertinoIcons.chart_bar_fill,
                  color: Colors.orange,
                ),

                _buildTimelineItem(
                  version: '0.4.0',
                  title: 'Social & Sharing',
                  subtitle: 'Connect with friends & share progress',
                  status: TimelineStatus.planned,
                  features: [
                    'Workout sharing capabilities',
                    'Progress photo integration',
                    'Achievement system',
                    'Workout challenges',
                    'Community features',
                  ],
                  icon: CupertinoIcons.person_2_fill,
                  color: Colors.purple,
                ),

                _buildTimelineItem(
                  version: '0.5.0',
                  title: 'AI Integration',
                  subtitle: 'Smart recommendations & form analysis',
                  status: TimelineStatus.planned,
                  features: [
                    'AI workout recommendations',
                    'Form analysis using camera',
                    'Personalized training plans',
                    'Smart rest period suggestions',
                    'Injury prevention insights',
                  ],
                  icon: CupertinoIcons.lightbulb_fill,
                  color: Colors.pink,
                ),

                _buildTimelineItem(
                  version: '1.0.0+',
                  title: 'Beyond',
                  subtitle: 'Wearable integration & advanced features',
                  status: TimelineStatus.future,
                  features: [
                    'Apple Watch integration',
                    'Heart rate monitoring',
                    'Advanced biometric tracking',
                    'Nutrition integration',
                    'Sleep pattern analysis',
                  ],
                  icon: CupertinoIcons.infinite,
                  color: Colors.cyan,
                ),

                const SizedBox(height: 32),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.heart_fill, color: Colors.red, size: 24),
                      const SizedBox(height: 8),
                      const Text(
                        'Built with passion for fitness',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your feedback shapes our roadmap',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String version,
    required String title,
    required String subtitle,
    required TimelineStatus status,
    required List<String> features,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status == TimelineStatus.completed 
                      ? color 
                      : status == TimelineStatus.inProgress
                          ? color.withOpacity(0.7)
                          : Colors.grey[700],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: status == TimelineStatus.completed 
                        ? color 
                        : status == TimelineStatus.inProgress
                            ? color
                            : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: status == TimelineStatus.completed 
                      ? Colors.white 
                      : status == TimelineStatus.inProgress
                          ? Colors.white
                          : Colors.grey[400],
                  size: 20,
                ),
              ),
              if (version != '1.0.0+')
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[700],
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == TimelineStatus.inProgress 
                      ? color.withOpacity(0.5) 
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          version,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Features
                  ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.circle_fill,
                          size: 6,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TimelineStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TimelineStatus.completed:
        color = Colors.green;
        text = 'Released';
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case TimelineStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        icon = CupertinoIcons.clock_fill;
        break;
      case TimelineStatus.planned:
        color = Colors.orange;
        text = 'Planned';
        icon = CupertinoIcons.calendar;
        break;
      case TimelineStatus.future:
        color = Colors.grey;
        text = 'Future';
        icon = CupertinoIcons.star_fill;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum TimelineStatus {
  completed,
  inProgress,
  planned,
  future,
}
