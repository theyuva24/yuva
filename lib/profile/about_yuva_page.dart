import 'package:flutter/material.dart';
import 'package:yuva/universal/theme/app_theme.dart';

class AboutYuvaPage extends StatelessWidget {
  const AboutYuvaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeLight.background,
      appBar: AppBar(
        backgroundColor: AppThemeLight.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About YUVA',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About YUVA',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Last Updated: July 22, 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '1. Our Story & Evolution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Founding: YUVA was conceived in early 2025 by a group of educators and technologists who recognized the need for a single digital space where learning, community, and career development converge.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Milestones:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Q1 2025: Concept ideation and market research.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Q2 2025: MVP development with core features—discussion hubs, challenges, profiles.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'July 2025: Public launch of YUVA V1.0 on Android and iOS.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Since launch, thousands of users have joined study hubs, completed challenges, and built meaningful connections.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '2. Our Vision',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'To create a vibrant, community-driven ecosystem where every student has seamless access to peers, mentors, resources, and opportunities to unlock their full potential.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '3. Our Mission',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '1. Facilitate Knowledge Sharing: Enable students to ask questions, share insights, and collaborate across subjects.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '2. Promote Skill Development: Offer curated challenges, micro-courses, and resources to build in-demand skills.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '3. Empower Career Growth: Provide a platform to showcase achievements, build professional profiles, and connect with recruiters.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '4. Foster Engagement: Use gamification, rewards, and progress-tracking to motivate continuous learning.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '4. Core Values',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Community First: We believe learning thrives in collaborative environments.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Accessibility: Education and networking opportunities should be within everyone’s reach.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Innovation: We continually refine our features to stay ahead of evolving user needs.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Integrity: We safeguard user data, respect privacy, and uphold transparency.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Empowerment: We aim to build confidence through recognition and rewards.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '5. Key Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '5.1 Hubs & Discussions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Subject-Focused Hubs: Join or create hubs for topics ranging from STEM to soft skills.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Threaded Conversations: Engage in organized, threaded discussions with tagging and search.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Anonymous Posting: Ask sensitive or bold questions without revealing your identity.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '5.2 Challenges & Learning Paths',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Skill Challenges: Participate in expert-designed challenges with clear goals and deadlines.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Progress Tracking: Monitor your completion status, earn badges, and share results.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Leaderboards & Rewards: Compete with peers and earn points redeemable for certificates or partner perks.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '5.3 Professional Profiles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Customizable Profiles: Highlight education, projects, skills, and achievements.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Resume Builder: Generate a formatted resume using in-app data.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Network Connections: Follow peers, mentors, and recruiters; get notified of relevant opportunities.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '5.4 Resources & Courses',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Curated Content: Access recommended articles, videos, and micro-courses from trusted providers.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Search & Filter: Find resources by topic, difficulty, or format.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Bookmark & Share: Save resources for offline reading and share with your network.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '5.5 Safety & Moderation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Community Guidelines: Enforced rules to ensure respectful, constructive interactions.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Reporting Tools: Flag inappropriate content for quick review by our moderation team.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Data Protection: End-to-end encryption for private messages; robust safeguards for user data.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '6. Leadership & Team',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Founder & CEO: [Name], an ed-tech veteran with 10+ years in digital learning platforms.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'CTO: [Name], expert in scalable mobile architectures and AI-powered recommendation systems.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Head of Community: [Name], responsible for hub curation, events, and user engagement.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Advisory Board: Includes educators, career coaches, and industry recruiters guiding YUVA’s strategic direction.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Our diverse team combines expertise in technology, education, design, and community building to deliver an exceptional user experience.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '7. Partnerships & Collaborations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'We partner with leading educational content providers, certification bodies, and corporate sponsors to bring you:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Exclusive Workshops & Webinars',
                style: TextStyle(fontSize: 16),
              ),
              Text('Certification Discounts', style: TextStyle(fontSize: 16)),
              Text('Internship & Job Listings', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text(
                'Want to collaborate? Reach out to partnerships@yuvaapp.com.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '8. Contact & Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'For assistance, feedback, or general inquiries, please contact us at:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Email: support@yuvaapp.com',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Address: 123 Tech Park Road, Bengaluru, Karnataka, India',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Social: @yuva_app on Twitter, Instagram, and LinkedIn',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Thank you for being part of the YUVA community!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '© 2025 YUVA Tech Pvt. Ltd. • All rights reserved.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
