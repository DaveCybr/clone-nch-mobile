import 'package:flutter/material.dart';
import 'package:nch_mobile/v1/features/login/models/auth_model.dart';

class DashboardHeader extends StatelessWidget {
  final UserModel? currentUser;
  final PageController pageController;
  final List<String> bannerImages;
  final int currentBannerIndex;

  const DashboardHeader({
    super.key,
    required this.currentUser,
    required this.pageController,
    required this.bannerImages,
    required this.currentBannerIndex,
  });

  String getSalam() {
    final hour = DateTime.now().hour;
    String timeGreeting =
        hour < 12
            ? 'Selamat Pagi'
            : hour < 15
            ? 'Selamat Siang'
            : hour < 18
            ? 'Selamat Sore'
            : 'Selamat Malam';

    String genderGreeting =
        currentUser?.gender == 'MALE'
            ? 'Bapak'
            : currentUser?.gender == 'FEMALE'
            ? 'Ibu'
            : 'Guru';

    return '$timeGreeting, $genderGreeting';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        image: DecorationImage(
          image: AssetImage('assets/bg-dashboard.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color(0xFF0F7836).withOpacity(0.7),
            BlendMode.srcOver,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF0F7836).withOpacity(0.9),
            const Color(0xFF0F7836).withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getSalam(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        currentUser?.name ?? 'Pengguna',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: Text(
                      currentUser?.name.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: bannerImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          bannerImages[index],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  bannerImages.map((image) {
                    int index = bannerImages.indexOf(image);
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            currentBannerIndex == index
                                ? Colors.white
                                : Colors.white54,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
