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
    final bool isHealthy = (widget.aiData['severity']?.toString() ?? 'none')
                .toLowerCase() ==
            'none' ||
        (widget.aiData['disease']?.toString() ?? 'Không rõ').toLowerCase() ==
            'khỏe mạnh';

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
    // Sử dụng cấu trúc dữ liệu gốc từ API
    final String diseaseName =
        widget.aiData['disease']?.toString() ?? 'Không rõ';
    final double confidence = (widget.aiData['confidence'] is num)
        ? (widget.aiData['confidence'] as num).toDouble()
        : 0.0;
    final String severity = widget.aiData['severity']?.toString() ?? 'none';
    // Tự suy luận cây có khỏe mạnh không dựa trên mức độ nghiêm trọng
    final bool isHealthy = severity.toLowerCase() == 'none' ||
        diseaseName.toLowerCase() == 'khỏe mạnh';
    final String description =
        widget.aiData['description']?.toString() ?? 'Không có mô tả chi tiết.';

    final List<String> symptoms = (widget.aiData['symptoms'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final List<String> solutions =
        (widget.aiData['solutions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
    final List<String> treatmentSteps =
        (widget.aiData['treatmentSteps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
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
                      angle: 0.8, // Nghiêng lá tạo cảm giác héo úa
                      child: Icon(Icons.eco_rounded,
                          color: _colorAnimation!.value, size: 40),
                    ),
                  ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diseaseName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: Text(
              'Độ tin cậy: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: confidence > 0.8 ? Colors.green.shade700 : Colors.orange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Mô tả chi tiết',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 20),
        if (symptoms.isNotEmpty) ...[
          const Text('Triệu chứng nhận biết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...symptoms.map((symptom) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontSize: 18, color: Colors.orange)),
                    Expanded(
                        child: Text(symptom,
                            style: const TextStyle(fontSize: 15, height: 1.4))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (treatment.isNotEmpty) ...[
          const Text('Hướng dẫn xử lý',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
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
                  .map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.healing,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(step,
                                    style: const TextStyle(
                                        fontSize: 15, height: 1.4))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        if (weatherData != null || iotData != null) ...[
          const SizedBox(height: 20),
          const Text('Dữ liệu môi trường lúc phân tích',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal)),
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
                          Colors.orange),
                      _buildMetric(
                          Icons.water_drop,
                          '${weatherData['humidity'] ?? '-'}%',
                          'Độ ẩm',
                          Colors.blue),
                    ],
                  ),
                  if (weatherData['condition'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: Text('Thời tiết: ${weatherData['condition']}',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                                fontSize: 13)),
                      ),
                    ),
                  if (iotData != null) const Divider(height: 32),
                ],
                if (iotData != null) ...[
                  Row(
                    children: [
                      if (iotData['soilMoisture'] != null)
                        _buildMetric(Icons.grass, '${iotData['soilMoisture']}%',
                            'Ẩm đất', Colors.brown),
                      if (iotData['lightIntensity'] != null)
                        _buildMetric(
                            Icons.light_mode,
                            '${iotData['lightIntensity']} lux',
                            'Ánh sáng',
                            Colors.amber.shade600),
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
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color.withOpacity(0.9))),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.6)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
