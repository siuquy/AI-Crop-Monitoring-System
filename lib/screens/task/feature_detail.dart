import 'package:flutter/material.dart';

enum FeatureType {
  monitoring,
  pestDetection,
  taskManagement,
}

const Color primaryTeal = Color(0xFF1FCFC5);
const Color darkTeal = Color(0xFF14B8B0);

class FeatureDetailScreen extends StatelessWidget {
  final FeatureType type;

  const FeatureDetailScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final feature = _getFeatureContent(type);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          feature.appBarTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        feature.imagePath,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Minh hoạ thao tác quét AI',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Các bước thực hiện',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                ...List.generate(
                  feature.steps.length,
                  (index) => _StepItem(
                    index: index + 1,
                    title: feature.steps[index].title,
                    description: feature.steps[index].description,
                  ),
                ),

                const SizedBox(height: 60),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int index;
  final String title;
  final String description;

  const _StepItem({
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureStep {
  final String title;
  final String description;

  FeatureStep({
    required this.title,
    required this.description,
  });
}

class FeatureContent {
  final String appBarTitle;
  final String imagePath;
  final List<FeatureStep> steps;

  FeatureContent({
    required this.appBarTitle,
    required this.imagePath,
    required this.steps,
  });
}

FeatureContent _getFeatureContent(FeatureType type) {
  switch (type) {
    case FeatureType.pestDetection:
      return FeatureContent(
        appBarTitle: 'Hướng dẫn quét sâu bệnh AI',
        imagePath: 'assets/pest_detection.jpg',
        steps: [
          FeatureStep(
            title: 'Quét lá cà chua',
            description:
                'Hướng camera về phía lá cà chua có dấu hiệu bất thường để nhận diện.',
          ),
          FeatureStep(
            title: 'Phân tích AI',
            description:
                'Giữ máy ổn định trong khoảng 3–5 giây để AI phân tích hình ảnh chính xác.',
          ),
          FeatureStep(
            title: 'Báo cáo',
            description:
                'Xem kết quả chẩn đoán bệnh và gửi báo cáo về hệ thống trung tâm.',
          ),
        ],
      );

    case FeatureType.monitoring:
    case FeatureType.taskManagement:
      return FeatureContent(
        appBarTitle: 'Hướng dẫn',
        imagePath: 'assets/monitoring.jpg',
        steps: [],
      );
  }
}
