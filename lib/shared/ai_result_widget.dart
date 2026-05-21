import 'package:flutter/material.dart';

class AiResultWidget extends StatefulWidget {
  final Map<String, dynamic> aiData;

  const AiResultWidget({super.key, required this.aiData});

  @override
  State<AiResultWidget> createState() => _AiResultWidgetState();
}

class _AiResultWidgetState extends State<AiResultWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Color?>? _colorAnimation;

  @override
  void initState() {
    super.initState();

    final severity = _vi(widget.aiData['severity']?.toString() ?? 'none');
    final disease = _vi(widget.aiData['disease']?.toString() ?? 'Không rõ');

    final bool isHealthy = severity.toLowerCase() == 'không có' ||
        severity.toLowerCase() == 'none' ||
        disease.toLowerCase() == 'khỏe mạnh';

    if (!isHealthy) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      )..repeat(reverse: true);

      _colorAnimation =
          ColorTween(begin: Colors.red.shade600, end: Colors.orange.shade700)
              .animate(_controller!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String diseaseName =
        _vi(widget.aiData['disease']?.toString() ?? 'Không rõ');

    final double confidence = _parseConfidence(widget.aiData['confidence']);

    final String severity =
        _vi(widget.aiData['severity']?.toString() ?? 'Không có');

    final bool isHealthy = severity.toLowerCase() == 'không có' ||
        severity.toLowerCase() == 'none' ||
        diseaseName.toLowerCase() == 'khỏe mạnh';

    final String description = _vi(
      widget.aiData['description']?.toString() ?? 'Không có mô tả chi tiết.',
    );

    final List<String> symptoms = _toList(widget.aiData['symptoms'])
        .map((e) => _vi(e))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final List<String> solutions = _toList(widget.aiData['solutions'])
        .map((e) => _vi(e))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final List<String> treatmentSteps = _toList(widget.aiData['treatmentSteps'])
        .map((e) => _vi(e))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final List<String> treatment = [...solutions, ...treatmentSteps];

    final weatherData =
        widget.aiData['weatherDataUsed'] as Map<String, dynamic>?;
    final iotData = widget.aiData['iotDataUsed'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: isHealthy || _colorAnimation == null
                ? Icon(
                    isHealthy ? Icons.check_circle : Icons.eco_rounded,
                    color: isHealthy ? Colors.green : Colors.red,
                    size: 40,
                  )
                : AnimatedBuilder(
                    animation: _colorAnimation!,
                    builder: (context, child) => Transform.rotate(
                      angle: 0.8,
                      child: Icon(
                        Icons.eco_rounded,
                        color: _colorAnimation!.value,
                        size: 40,
                      ),
                    ),
                  ),
            title: Text(
              diseaseName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Độ tin cậy AI ước lượng: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: confidence > 0.8 ? Colors.green.shade700 : Colors.orange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mô tả chi tiết',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 20),
        if (symptoms.isNotEmpty) ...[
          const Text(
            'Triệu chứng nhận biết',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...symptoms.map(
            (symptom) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 18, color: Colors.orange),
                  ),
                  Expanded(
                    child: Text(
                      symptom,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (treatment.isNotEmpty) ...[
          const Text(
            'Hướng dẫn xử lý',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: treatment
                  .map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.healing,
                              size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (weatherData != null || iotData != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Dữ liệu môi trường lúc phân tích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (weatherData != null) ...[
                  Row(
                    children: [
                      _buildMetric(
                        Icons.thermostat,
                        '${weatherData['temperature'] ?? '-'}°C',
                        'Nhiệt độ',
                        Colors.orange,
                      ),
                      _buildMetric(
                        Icons.water_drop,
                        '${weatherData['humidity'] ?? '-'}%',
                        'Độ ẩm',
                        Colors.blue,
                      ),
                    ],
                  ),
                  if (weatherData['condition'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          'Thời tiết: ${_vi(weatherData['condition'].toString())}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (iotData != null) const Divider(height: 32),
                ],
                if (iotData != null) ...[
                  Row(
                    children: [
                      if (iotData['soilMoisture'] != null)
                        _buildMetric(
                          Icons.grass,
                          '${iotData['soilMoisture']}%',
                          'Ẩm đất',
                          Colors.brown,
                        ),
                      if (iotData['lightIntensity'] != null)
                        _buildMetric(
                          Icons.light_mode,
                          '${iotData['lightIntensity']} lux',
                          'Ánh sáng',
                          Colors.amber.shade600,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static double _parseConfidence(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      final v = value.toDouble();
      return v > 1 ? v / 100 : v;
    }

    final text = value.toString().replaceAll('%', '').trim();
    final parsed = double.tryParse(text);

    if (parsed == null) return 0;
    return parsed > 1 ? parsed / 100 : parsed;
  }

  static List<String> _toList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'\n|;|\|'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  static String _vi(String input) {
    var text = input.trim();

    final Map<String, String> dictionary = {
      'none': 'Không có',
      'None': 'Không có',
      'healthy': 'khỏe mạnh',
      'Healthy': 'Khỏe mạnh',
      'unknown': 'không xác định',
      'Unknown': 'Không xác định',
      'Low': 'Thấp',
      'Medium': 'Trung bình',
      'High': 'Cao',
      'Mild': 'Nhẹ',
      'Moderate': 'Trung bình',
      'Severe': 'Nặng',
      'Critical': 'Rất nặng',
      'Leaf spot': 'Bệnh đốm lá',
      'Powdery mildew': 'Bệnh phấn trắng',
      'Downy mildew': 'Bệnh sương mai',
      'Blight': 'Bệnh cháy lá',
      'Early blight': 'Bệnh cháy lá sớm',
      'Late blight': 'Bệnh cháy lá muộn',
      'Rust': 'Bệnh gỉ sắt',
      'Root rot': 'Bệnh thối rễ',
      'Anthracnose': 'Bệnh thán thư',
      'Bacterial wilt': 'Bệnh héo xanh vi khuẩn',
      'Soft rot': 'Bệnh thối mềm',
      'Black rot': 'Bệnh thối đen',
      'Brown, soft, watery decay on the cabbage head, often with a foul odor.':
          'Phần đầu bắp cải bị thối nhũn, mềm, có màu nâu, úng nước và thường có mùi hôi.',
      'Brown, soft, watery decay':
          'Mô cây bị thối nhũn, mềm, có màu nâu và úng nước',
      'on the cabbage head': 'trên phần đầu bắp cải',
      'often with a foul odor': 'thường kèm theo mùi hôi',
      'Ensure proper drainage': 'Đảm bảo hệ thống thoát nước tốt',
      'Improve air circulation': 'Tăng độ thông thoáng không khí',
      'Avoid overhead watering':
          'Tránh tưới nước trực tiếp lên lá hoặc phần bắp',
      'Remove infected leaves': 'Loại bỏ lá hoặc mô cây bị bệnh',
      'Remove and destroy infected plants': 'Loại bỏ và tiêu hủy cây bị bệnh',
      'Sanitize tools after handling diseased plants':
          'Vệ sinh dụng cụ sau khi xử lý cây bệnh',
      'Rotate crops to reduce pathogen buildup':
          'Luân canh cây trồng để hạn chế mầm bệnh',
      'Apply fungicide': 'Sử dụng thuốc trừ nấm phù hợp',
      'Apply pesticide': 'Sử dụng thuốc bảo vệ thực vật phù hợp',
      'Monitor the plant': 'Theo dõi cây trồng thường xuyên',
      'Consult an agricultural specialist':
          'Tham khảo ý kiến chuyên gia nông nghiệp',
      'Yellowing leaves': 'Lá bị vàng',
      'brown spots': 'đốm nâu',
      'yellow spots': 'đốm vàng',
      'white powder': 'lớp phấn trắng',
      'wilting': 'héo lá',
      'leaf curling': 'xoăn lá',
      'fungal infection': 'nhiễm nấm',
      'bacterial infection': 'nhiễm vi khuẩn',
      'viral infection': 'nhiễm virus',
    };

    dictionary.forEach((en, vi) {
      text = text.replaceAll(en, vi);
    });

    return text;
  }
}
